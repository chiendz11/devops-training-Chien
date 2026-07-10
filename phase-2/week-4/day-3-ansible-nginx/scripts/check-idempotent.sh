#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ansible-playbook \
  -i inventory/hosts.yml \
  playbooks/site.yml \
  --vault-password-file vault/.vault-pass \
  | tee /tmp/ansible-nginx-idempotent.log

if grep -qE 'changed=[1-9]' /tmp/ansible-nginx-idempotent.log; then
  echo "Idempotent check failed: changed task found on second run"
  exit 1
fi

echo "Idempotent check passed: no changed task on repeated run"

