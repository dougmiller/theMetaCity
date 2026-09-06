# mTLS + rate limiting (production edge)

Security lives entirely at nginx. **Dev is untouched** — `podman-compose.yml`,
`nginx.conf`, `conf.d/`, and `flask run` all behave exactly as before. Everything
here is opt-in via the separate prod stack.

## What was added
- `scripts/gen-certs.sh` — generates the CA, server cert, client cert, `client.p12`.
- `podman/nginx/nginx.prod.conf` — prod nginx (adds the rate-limit zones).
- `podman/nginx/conf.d.prod/flask-app.conf` — `:443` TLS + mTLS + rate limit; `:80` health + https redirect.
- `podman-compose.prod.yml` — self-contained prod stack (run explicitly).
- `podman/nginx/certs/` — where the generated certs live (git-ignored).
- Makefile targets: `certs`, `up-prod`, `down-prod`, `rebuild-prod`, `logs-prod`, `ps-prod`.

## 1. Generate certs (once)
```bash
# bare run = working local test set (server valid for localhost/127.0.0.1)
make certs

# for real deployment, name the host(s)/IP the app will connect to:
SERVER_CN=api.themetacity.com \
SERVER_SANS="DNS:api.themetacity.com,IP:203.0.113.5" \
CLIENT_P12_PASS='pick-a-strong-pass' ./scripts/gen-certs.sh
```
Guard `podman/nginx/certs/ca.key` — keep it off the server and out of git (it already is).
Rotate the leaf certs before they expire (~825 days); re-running the script keeps the CA and reissues them.

## 2. Run the prod stack
```bash
make down        # make sure the dev stack is not running (shared ports)
make up-prod     # podman-compose -f podman-compose.prod.yml up -d
```

## 3. Test it
```bash
# no client cert -> rejected at the TLS handshake (400)
curl -k https://localhost/            # fails: "No required SSL certificate was sent"

# with the client cert -> passes through to Flask
curl --cert podman/nginx/certs/client.crt \
     --key  podman/nginx/certs/client.key \
     --cacert podman/nginx/certs/ca.crt \
     https://localhost/

# health is reachable without a cert (for uptime monitors), on :80
curl http://localhost/health
```

## Bruno
In the collection/environment settings add a client certificate for the host
(cert = `client.crt`, key = `client.key`), or point Bruno at Flask directly
during dev to skip mTLS entirely.

## Android (OkHttp)
Load `client.p12` into a KeyManager and attach it to the OkHttp client (see the
snippet discussed in chat). Use a **debug build variant** that talks plain HTTP
to your local box (no cert) and a **release variant** that uses HTTPS + the
client cert, so app development has no cert friction.

## Notes
- `server_name _;` accepts any host — the client cert, not the hostname, gates
  access. If you switch the server cert to Let's Encrypt, set `server_name` to
  your real domain in `conf.d.prod/flask-app.conf`.
- The verified client identity is passed to Flask as the `X-Client-Cert-CN` header.
- Optional follow-up (correctness, not security): if `url_for(_external=True)`
  should emit `https`, wrap the app in werkzeug's `ProxyFix` so it trusts
  `X-Forwarded-Proto` from nginx.
