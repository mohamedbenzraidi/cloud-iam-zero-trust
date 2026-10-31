#!/usr/bin/env bash
# Destruction complète du laboratoire (maîtrise des coûts). Demande confirmation.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

read -r -p "Détruire l'infrastructure AWS et Keycloak ? (oui/non) " ans
[ "$ans" = "oui" ] || { echo "Annulé."; exit 1; }

( cd "$ROOT/terraform/environments/lab" && terraform destroy )
docker compose -f "$ROOT/idp/keycloak/docker-compose.yml" down -v
echo "Terminé. Les comptes membres ne sont fermés que si close_accounts_on_destroy = true (voir README)."
