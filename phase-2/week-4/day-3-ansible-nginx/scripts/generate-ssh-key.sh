#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .ssh
chmod 700 .ssh

KEY_PATH=".ssh/ansible_lab"

if [[ -f "$KEY_PATH" && -f "$KEY_PATH.pub" ]]; then
  echo "SSH key already exists: $KEY_PATH"
  exit 0
fi

ssh-keygen \
  -t ed25519 \
  -N "" \
  -C "ansible-nginx-lab" \
  -f "$KEY_PATH" \
  >/dev/null

chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

echo "Generated SSH key pair:"
echo "- private key: $KEY_PATH"
echo "- public key : $KEY_PATH.pub"

