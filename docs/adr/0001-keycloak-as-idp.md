# ADR 0001 : Keycloak comme fournisseur d'identité

**Statut** : accepté
**Contexte** : besoin d'un IdP SAML gratuit, reproductible en laboratoire.
**Décision** : Keycloak (Docker) avec realm importé ; Entra ID reste une option documentée.
**Conséquences** : pas de SCIM natif (provisionnement manuel/scripté), pas de haute disponibilité, durcissement production hors périmètre.
