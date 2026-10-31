#!/usr/bin/env bash
# Crée les groupes/utilisateurs de test dans Keycloak (realm "lab") avec un mot de passe temporaire
# et l'action obligatoire CONFIGURE_TOTP (OTP imposé à la première connexion).
# Usage : EMAIL_DOMAIN=example.com KEYCLOAK_ADMIN_PASSWORD=... ./scripts/create-test-users.sh
# Les e-mails DOIVENT être identiques à ceux de la variable Terraform "users".
set -euo pipefail

CONTAINER="${CONTAINER:-keycloak}"
REALM="${REALM:-lab}"
ADMIN="${KEYCLOAK_ADMIN:-admin}"
: "${KEYCLOAK_ADMIN_PASSWORD:?définir KEYCLOAK_ADMIN_PASSWORD}"
DOMAIN="${EMAIL_DOMAIN:-example.com}"
KCADM="docker exec -i ${CONTAINER} /opt/keycloak/bin/kcadm.sh"

$KCADM config credentials --server http://localhost:8080 --realm master \
  --user "$ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD" >/dev/null

# nom:groupe:Prénom:Nom
USERS=(
  "alice:cloud-admins:Alice:Admin"
  "bob:developers:Bob:Dev"
  "carol:auditors:Carol:Audit"
  "dave:developers:Dave:Dev"
)

group_id() { $KCADM get groups -r "$REALM" --fields id,name --format csv --noquotes | awk -F, -v n="$1" '$2==n {print $1}' | tr -d '\r'; }

echo "Utilisateur ; mot de passe temporaire (à changer + OTP à la première connexion)"
for entry in "${USERS[@]}"; do
  IFS=: read -r name grp first last <<<"$entry"
  email="${name}@${DOMAIN}"
  pass="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-16)Aa1"

  if [ -n "$($KCADM get users -r "$REALM" -q "username=$name" --fields id --format csv --noquotes | tr -d '\r')" ]; then
    echo "$name existe déjà, ignoré"; continue
  fi

  $KCADM create users -r "$REALM" -s "username=$name" -s "email=$email" -s "firstName=$first" -s "lastName=$last" \
    -s enabled=true -s emailVerified=true -s 'requiredActions=["CONFIGURE_TOTP","UPDATE_PASSWORD"]' >/dev/null
  $KCADM set-password -r "$REALM" --username "$name" --new-password "$pass" --temporary
  uid="$($KCADM get users -r "$REALM" -q "username=$name" --fields id --format csv --noquotes | tr -d '\r')"
  gid="$(group_id "$grp")"
  $KCADM update "users/${uid}/groups/${gid}" -r "$REALM" -s "realm=${REALM}" -s "userId=${uid}" -s "groupId=${gid}" -n
  echo "${email} ; ${pass} ; groupe ${grp}"
done
