#!/usr/bin/env bash
# Déploiement en deux temps : les providers des comptes membres dépendent d'IDs créés par Organizations.
# Usage : ./scripts/deploy.sh [plan|apply]
set -euo pipefail

ACTION="${1:-plan}"
cd "$(dirname "$0")/../terraform/environments/lab"

terraform init -backend-config=backend.hcl

if [ "$ACTION" = "apply" ]; then
  echo ">> Étape 1/2 : organisation et comptes"
  terraform apply -target=module.organization
  echo ">> Étape 2/2 : reste de l'infrastructure"
  terraform apply
else
  terraform plan -target=module.organization
  echo "(le plan complet n'est possible qu'après l'étape 1 : lancez './scripts/deploy.sh apply')"
fi
