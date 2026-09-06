#!/usr/bin/env bash
#
# gen-certs.sh — generate the mTLS trust material for theMetaCity.
#
# Produces (in the output dir, default: podman/nginx/certs):
#   ca.crt          — your private Certificate Authority (the trust anchor).
#   ca.key          — CA private key. GUARD THIS. Do not deploy it, do not commit it.
#   server.crt      — TLS server cert nginx presents (signed by your CA).
#   server.key      — server private key (lives on the server, mounted into nginx).
#   client.crt      — the Android app's identity cert (signed by your CA).
#   client.key      — client private key.
#   client.p12      — client cert + key bundled for Android/Bruno/curl import.
#
# nginx only needs: ca.crt, server.crt, server.key.
# The Android app needs: client.p12 (and ca.crt, if you pin the CA for server trust).
#
# Usage:
#   SERVER_CN=api.themetacity.com SERVER_SANS="DNS:api.themetacity.com,IP:203.0.113.5" \
#   CLIENT_P12_PASS='choose-a-strong-pass' ./gen-certs.sh
#
# Everything has a default so you can run it bare to get a working local test set.
#
set -euo pipefail

OUT_DIR="${OUT_DIR:-$(cd "$(dirname "$0")/.." && pwd)/podman/nginx/certs}"
DAYS_CA="${DAYS_CA:-3650}"      # CA valid 10 years
DAYS_LEAF="${DAYS_LEAF:-825}"   # server/client valid ~2.25 years (rotation clock)

SERVER_CN="${SERVER_CN:-localhost}"
# SANs the server cert is valid for. Add every hostname/IP the app connects to.
SERVER_SANS="${SERVER_SANS:-DNS:localhost,IP:127.0.0.1}"
CLIENT_CN="${CLIENT_CN:-doug-android}"
CLIENT_P12_PASS="${CLIENT_P12_PASS:-}"

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# ---- 1. CA (create once; never clobber an existing CA) --------------------
if [[ -f ca.key ]]; then
  echo "==> ca.key already exists — reusing existing CA (delete ca.* to start over)."
else
  echo "==> Generating private CA..."
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -nodes -key ca.key -sha256 -days "$DAYS_CA" \
    -subj "/CN=TheMetaCity Private CA" -out ca.crt
fi

# ---- 2. Server cert (signed by CA, with SANs) -----------------------------
echo "==> Generating server cert for CN=$SERVER_CN (SANs: $SERVER_SANS)..."
openssl genrsa -out server.key 4096
openssl req -new -key server.key -subj "/CN=$SERVER_CN" -out server.csr
cat > server.ext <<EXT
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=$SERVER_SANS
EXT
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days "$DAYS_LEAF" -sha256 -extfile server.ext -out server.crt

# ---- 3. Client cert (the phone's identity, signed by CA) ------------------
echo "==> Generating client cert for CN=$CLIENT_CN..."
openssl genrsa -out client.key 4096
openssl req -new -key client.key -subj "/CN=$CLIENT_CN" -out client.csr
cat > client.ext <<EXT
basicConstraints=CA:FALSE
keyUsage=digitalSignature
extendedKeyUsage=clientAuth
EXT
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -days "$DAYS_LEAF" -sha256 -extfile client.ext -out client.crt

# ---- 4. Bundle client for Android / Bruno / curl --------------------------
if [[ -z "$CLIENT_P12_PASS" ]]; then
  CLIENT_P12_PASS="$(openssl rand -base64 18)"
  echo "==> No CLIENT_P12_PASS set; generated one (save it): $CLIENT_P12_PASS"
fi
openssl pkcs12 -export -inkey client.key -in client.crt -certfile ca.crt \
  -passout pass:"$CLIENT_P12_PASS" -out client.p12

# ---- tidy scratch ---------------------------------------------------------
rm -f server.csr client.csr server.ext client.ext

chmod 600 ca.key server.key client.key client.p12 2>/dev/null || true

echo
echo "==> Done. Files in: $OUT_DIR"
echo "    nginx needs:   ca.crt, server.crt, server.key"
echo "    Android needs: client.p12  (pass above)  + ca.crt if pinning server trust"
echo "    KEEP ca.key OFFLINE and OUT OF GIT. Rotate leaf certs before day $DAYS_LEAF."
