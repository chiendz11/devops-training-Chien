#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p vault

VAULT_PASS_FILE="${VAULT_PASS_FILE:-vault/.vault-pass}"
if [[ ! -f "$VAULT_PASS_FILE" ]]; then
  printf 'devops\n' > "$VAULT_PASS_FILE"
  chmod 600 "$VAULT_PASS_FILE"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

openssl req \
  -x509 \
  -nodes \
  -newkey rsa:2048 \
  -days 7 \
  -keyout "$TMP_DIR/demo.key" \
  -out "$TMP_DIR/demo.crt" \
  -subj "/CN=ansible-nginx.local" \
  -addext "subjectAltName=DNS:nginx1.local,DNS:nginx2.local,DNS:localhost,IP:127.0.0.1" \
  >/dev/null 2>&1

{
  printf '%s\n' '---'
  printf '%s\n' 'nginx_tls_cert: |'
  sed 's/^/  /' "$TMP_DIR/demo.crt"
  printf '%s\n' 'nginx_tls_key: |'
  sed 's/^/  /' "$TMP_DIR/demo.key"
} > vault/cert.yml

ansible-vault encrypt vault/cert.yml --vault-password-file "$VAULT_PASS_FILE"

printf 'Generated encrypted vault file: %s\n' "vault/cert.yml"
printf 'Vault password file: %s\n' "$VAULT_PASS_FILE"

