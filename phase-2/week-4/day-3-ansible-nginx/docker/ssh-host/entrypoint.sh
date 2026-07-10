#!/usr/bin/env bash
set -euo pipefail

if [[ ! -s /tmp/ansible_lab.pub ]]; then
  echo "Missing public key: /tmp/ansible_lab.pub"
  echo "Run scripts/generate-ssh-key.sh before docker compose up."
  exit 1
fi

install -d -m 0700 -o ansible -g ansible /home/ansible/.ssh
install -m 0600 -o ansible -g ansible /tmp/ansible_lab.pub /home/ansible/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e

