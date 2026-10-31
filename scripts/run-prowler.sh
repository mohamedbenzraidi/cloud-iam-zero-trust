#!/usr/bin/env bash
# Exécute Prowler (benchmark CIS) et enregistre le rapport dans reports/.
# Usage : AWS_PROFILE=<profil-sso-auditeur> ./scripts/run-prowler.sh before|after
# Vérifiez le nom exact du benchmark disponible : prowler aws --list-compliance
set -euo pipefail

LABEL="${1:?usage: run-prowler.sh before|after}"
COMPLIANCE="${COMPLIANCE:-cis_2.0_aws}"
OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/reports"
mkdir -p "$OUT_DIR"

command -v prowler >/dev/null || { echo "prowler introuvable : pip install prowler"; exit 1; }

prowler aws \
  --compliance "$COMPLIANCE" \
  --output-formats html csv json-ocsf \
  --output-directory "$OUT_DIR" \
  --output-filename "prowler-${LABEL}"

echo "Rapports écrits dans ${OUT_DIR} (prowler-${LABEL}*)."
echo "ATTENTION : les rapports contiennent des identifiants de compte. Masquez-les avant publication."
