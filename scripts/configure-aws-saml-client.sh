#!/usr/bin/env bash
# Crée dans Keycloak le client SAML qui représente AWS IAM Identity Center.
# À lancer APRÈS avoir choisi "External identity provider" dans Identity Center : la console affiche
#   - "IAM Identity Center Assertion Consumer Service (ACS) URL"
#   - "IAM Identity Center issuer URL"
# Usage : ACS_URL=... ISSUER_URL=... KEYCLOAK_ADMIN_PASSWORD=... ./scripts/configure-aws-saml-client.sh
set -euo pipefail

CONTAINER="${CONTAINER:-keycloak}"
REALM="${REALM:-lab}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
: "${KEYCLOAK_ADMIN_PASSWORD:?définir KEYCLOAK_ADMIN_PASSWORD}"
: "${ACS_URL:?définir ACS_URL (URL ACS de IAM Identity Center)}"
: "${ISSUER_URL:?définir ISSUER_URL (URL emetteur de IAM Identity Center)}"
KCADM="docker exec -i ${CONTAINER} /opt/keycloak/bin/kcadm.sh"

$KCADM config credentials --server http://localhost:8080 --realm master \
  --user "$ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD" >/dev/null

$KCADM create clients -r "$REALM" \
  -s "clientId=${ISSUER_URL}" \
  -s protocol=saml \
  -s name="AWS IAM Identity Center" \
  -s enabled=true \
  -s "baseUrl=${ACS_URL}" \
  -s "redirectUris=[\"${ACS_URL}\"]" \
  -s 'attributes."saml.authnstatement"=true' \
  -s 'attributes."saml.server.signature"=true' \
  -s 'attributes."saml.assertion.signature"=true' \
  -s 'attributes."saml.client.signature"=false' \
  -s 'attributes."saml_name_id_format"=email' \
  -s 'attributes."saml.force.post.binding"=true' \
  -s "attributes.\"saml_assertion_consumer_url_post\"=${ACS_URL}"

echo "Client créé. Métadonnées IdP à importer dans Identity Center :"
echo "  http://localhost:8080/realms/${REALM}/protocol/saml/descriptor  (ou https://<KC_HOSTNAME>/...)"
