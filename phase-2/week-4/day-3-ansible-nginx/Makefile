.PHONY: key up ping cert apply test idempotent clean

key:
	bash scripts/generate-ssh-key.sh

up: key
	docker compose up -d --build

ping:
	ansible -i inventory/hosts.yml nginx -m ping

cert:
	bash scripts/generate-vault-cert.sh

apply:
	ansible-playbook -i inventory/hosts.yml playbooks/site.yml --vault-password-file vault/.vault-pass

test:
	curl -s http://127.0.0.1:8081/health
	curl -sk https://127.0.0.1:8441/health
	curl -s http://127.0.0.1:8082/health
	curl -sk https://127.0.0.1:8442/health

idempotent:
	bash scripts/check-idempotent.sh

clean:
	docker compose down -v
