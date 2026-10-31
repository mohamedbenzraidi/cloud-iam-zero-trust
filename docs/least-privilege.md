# Moindre privilège avec Access Analyzer (phase 4)

1. **État « avant »** : `developers_use_least_privilege = false` (permission set `PowerUser-Dev`). Faire travailler le développeur sur de vrais cas (S3, Lambda, DynamoDB…) pendant quelques jours.
2. **Générer la politique** : console IAM > Access Analyzer > *Policy generation* sur le rôle SSO du développeur (rôle `AWSReservedSSO_PowerUser-Dev_…`), en pointant le trail d'organisation du compte `security`. Régler la période d'analyse.
3. **Réviser** la politique générée : remplacer les `*` restants, ajouter les conditions (`aws:RequestedRegion`, tags).
4. **Remplacer** le contenu de `policies/permission-sets/developer-least-privilege.json` (le fichier fourni est un point de départ générique, pas le résultat d'une analyse).
5. **Comparer** : nombre d'actions autorisées avant/après, reporté dans la section « Avant / Après » du README.
6. `developers_use_least_privilege = true` puis `terraform apply`.
7. **Accès inutilisé** : consulter les constats de l'analyseur `…-org-unused-access` et retirer les permissions concernées.

Rappel : les sessions SAML ne portent pas `aws:MultiFactorAuthPresent` ; le MFA se contrôle dans Keycloak.
