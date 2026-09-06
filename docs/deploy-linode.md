# Deploying theMetaCity to Linode (podman prod stack, mTLS)

First-launch runbook. Target: a fresh Linode (Akamai Cloud) compute instance
running the `podman-compose.prod.yml` stack (Postgres 18 + gunicorn + nginx),
with the API reachable over **mTLS on the instance's public IP** (self-signed
server cert, no domain, no Let's Encrypt). A later section covers moving to a
domain and splitting the API out.

Placeholders: `<LINODE_IP>` = the instance's public IPv4; `<YOUR_IP>` = your
home/office IP (for SSH lockdown); `<user>` = the deploy user you create.

---

## Phase 1 — Provision the Linode
1. Cloud Manager -> **Create -> Linode**.
2. **Image**: Debian 13 (Trixie). **Region**: Sydney (`ap-southeast`) for lowest
   latency to you and AU clients (Singapore `ap-south` if you'd rather sit in the
   same region as your object storage).
3. **Plan**: Shared CPU **2 GB** (Postgres + 4 gunicorn workers + nginx fit
   comfortably; the 1 GB Nanode is tight once Postgres warms up).
4. Set a strong **root password** and add your **SSH public key**.
5. (Recommended) Attach a **Cloud Firewall** now, or configure `ufw` in Phase 2.
6. Create, then note the **public IPv4** — that is `<LINODE_IP>`.

## Phase 2 — Harden the server
SSH in as root, then create a non-root sudo user and lock SSH down.
```bash
ssh root@<LINODE_IP>

apt update && apt -y upgrade
apt -y install sudo rsync            # Debian minimal images ship neither

adduser <user>
usermod -aG sudo <user>
rsync --archive --chown=<user>:<user> ~/.ssh /home/<user>   # copy your key over

# harden sshd
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
```
Firewall — open only SSH (locked to your IP) and the API port:
```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow from <YOUR_IP> to any port 22 proto tcp   # SSH from you only
ufw allow 443/tcp                                    # the mTLS API
# ufw allow 80/tcp                                   # OPTIONAL: only if you want
                                                     # the cert-free /health on :80
ufw enable
```
Postgres is never published to the host in the prod compose, so there is no
`5432` rule to add — the DB is reachable only inside the podman network.
Reconnect from now on as `ssh <user>@<LINODE_IP>`.

## Phase 3 — Install podman + podman-compose
```bash
sudo apt -y install podman podman-compose git
podman --version && podman-compose --version
```
Debian 13 ships podman 5.x and podman-compose in the standard repos — no extra
repositories needed.
This runbook runs the stack **rootful** (via a systemd unit in Phase 8) so it can
bind :443 and start on boot without extra tuning. (Rootless is possible but needs
`net.ipv4.ip_unprivileged_port_start` lowered and fiddlier networking — not worth
it for a single-tenant box.)

## Phase 4 — Get the code onto the server
Your repo is private, so use a **read-only deploy key**:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/deploy_tmc -N ""
cat ~/.ssh/deploy_tmc.pub    # add this as a DEPLOY KEY (read-only) on your Git host
git -c core.sshCommand="ssh -i ~/.ssh/deploy_tmc" \
    clone <your-git-remote> ~/theMetaCityFlask
cd ~/theMetaCityFlask
```
(Alternative: `rsync -av --exclude .git --exclude .venv ./ <user>@<LINODE_IP>:~/theMetaCityFlask/`
from your laptop. Commit first so you deploy a known revision.)

## Phase 5 — Create prod secrets & config (all git-ignored)
None of these come from git — create them on the server.
```bash
cd ~/theMetaCityFlask

# DB role passwords -> podman's own secret store (no plaintext files on disk).
# Rootful, to match the rootful stack (Phase 8). Piping straight from openssl
# means the plaintext only ever exists in podman's store and the container's
# ephemeral .pgpass -- never in a file you have to remember to delete.
openssl rand -base64 24 | sudo podman secret create postgres_password -
openssl rand -base64 24 | sudo podman secret create tmc_master_password -
openssl rand -base64 24 | sudo podman secret create tmc_selector_password -
sudo podman secret ls

# app config — start from the examples, then edit
cp .env.database.example .env.database
$EDITOR .env.basic .env.database
```
In `.env.basic` for production, make sure:
- `DEBUG=False` (never True on a public box).
- `SECRET_KEY=` a fresh strong random value: `openssl rand -hex 32`.
- `SERVER_NAME=<LINODE_IP>` (or leave host-agnostic; the mTLS gate is the cert,
  not the hostname).
- S3 keys: use **rotated** Linode Object Storage keys, not the ones from dev.
Make sure `.env.database` matches the passwords you just wrote into the secrets
files.

> **Rotating a DB password later**: the init scripts only set roles on the *first*
> DB init, so rotation is three steps — `sudo podman secret rm <name>` then
> recreate it (podman 5.x also has `--replace`), `ALTER USER <role> WITH PASSWORD`
> in Postgres to the same new value, and restart the stack so the container
> rebuilds `.pgpass`.

## Phase 6 — Install the TLS/mTLS certs
Best practice: **generate the CA on your laptop and keep `ca.key` there** — the
server only needs `server.crt`, `server.key`, and `ca.crt`. The public IP must be
in the server cert's SANs.

On your laptop, in the repo:
```bash
SERVER_CN=<LINODE_IP> \
SERVER_SANS="IP:<LINODE_IP>" \
CLIENT_P12_PASS='pick-a-strong-pass' ./scripts/gen-certs.sh
```
Copy only the three files the server needs (never `ca.key`, never the client key):
```bash
ssh <user>@<LINODE_IP> 'mkdir -p ~/theMetaCityFlask/podman/nginx/certs'
scp podman/nginx/certs/{ca.crt,server.crt,server.key} \
    <user>@<LINODE_IP>:~/theMetaCityFlask/podman/nginx/certs/
```
Keep `client.p12` for the phone (Phase 10) and guard `ca.key` offline.

## Phase 7 — Launch the stack
```bash
cd ~/theMetaCityFlask
sudo podman-compose -f podman-compose.prod.yml up -d --build
```
First boot: Postgres init scripts create the roles/schemas, then the flask
entrypoint runs `flask db upgrade`. Watch it come up:
```bash
sudo podman-compose -f podman-compose.prod.yml logs -f
sudo podman ps
```

## Phase 8 — Start on boot (systemd)
```bash
sudo tee /etc/systemd/system/tmc-prod.service >/dev/null <<UNIT
[Unit]
Description=theMetaCity prod stack (podman-compose)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/<user>/theMetaCityFlask
ExecStart=/usr/bin/podman-compose -f podman-compose.prod.yml up -d
ExecStop=/usr/bin/podman-compose -f podman-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable --now tmc-prod.service
```

## Phase 9 — Smoke test (from your laptop)
```bash
# no client cert -> rejected at the handshake (400)
curl -k https://<LINODE_IP>/ -i | head -1

# with the client cert -> passes through to Flask
curl --cert podman/nginx/certs/client.crt \
     --key  podman/nginx/certs/client.key \
     --cacert podman/nginx/certs/ca.crt \
     https://<LINODE_IP>/ -i | head -1

# health (only if you opened :80)
curl http://<LINODE_IP>/health
```
`--cacert ca.crt` is what lets curl trust the self-signed server cert; the app
does the same by pinning `ca.crt`.

## Phase 10 — Point the Android app
Load `client.p12` into the OkHttp client (KeyManager) and pin `ca.crt` for server
trust. Base URL = `https://<LINODE_IP>/`. Use a debug build variant against your
local box and a release variant against the Linode, as in `docs/mtls-setup.md`.

## Phase 11 — Post-deploy checklist
- [ ] `DEBUG=False` confirmed in the running container.
- [ ] Old S3 keys **rotated** in Linode Object Storage (the dev set was exposed).
- [ ] **Backups**: enable Linode Backups on the instance, and/or a nightly
      `pg_dump` cron to object storage.
- [ ] **Log rotation**: nginx logs live in the `nginx_logs_prod` volume — add
      logrotate or cap growth.
- [ ] **Unattended security updates**: `sudo apt install unattended-upgrades`.
- [ ] Note the cert **rotation date** (~825 days) — rerun `gen-certs.sh` (it keeps
      the CA, reissues leaves) and recopy server files before expiry.

## Redeploy / update flow
```bash
cd ~/theMetaCityFlask
git -c core.sshCommand="ssh -i ~/.ssh/deploy_tmc" pull
sudo podman-compose -f podman-compose.prod.yml up -d --build
```
Migrations run automatically via the entrypoint on container start.

## Later: growing past IP-only
You picked IP + self-signed for now with an eye to expanding — nothing here is a
dead end, because all of it terminates at nginx:
- **Move to a domain + public TLS**: point DNS at `<LINODE_IP>`, open `80/tcp`,
  install certbot, swap `server.crt`/`server.key` for the Let's Encrypt pair, set
  `server_name` in `conf.d.prod/flask-app.conf` to the domain. The mTLS client
  layer is unchanged. (Your own CA can keep signing client certs regardless.)
- **Split the API into its own service/subdomain**: add a second `server {}`
  block (e.g. `api.themetacity.com`) or a location prefix in `conf.d.prod`, or run
  the API as a separate upstream/container — nginx routes by host or path. mTLS
  can stay on just the API server block while a public site stays open.
- **Scale out**: move Postgres to a managed Linode DB, or the API to its own
  instance behind the same nginx, when traffic justifies it.
