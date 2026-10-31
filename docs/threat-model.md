# Modèle de menaces

| # | Menace | Impact | Mesure | Preuve / test |
|---|--------|--------|--------|---------------|
| 1 | Vol de mot de passe | Accès non autorisé | MFA/OTP imposé par Keycloak (action obligatoire CONFIGURE_TOTP), politique de mot de passe, protection anti-force brute | Test 2 |
| 2 | Vol de clé d'accès | Accès persistant | Aucune clé humaine (SCP `deny-iam-users-and-keys`), OIDC pour la CI | Test 1, Prowler |
| 3 | Escalade de privilèges | Prise de contrôle du compte | Permissions boundaries (`developer-boundary`), SCP, interdiction de retirer la boundary | Test 1 |
| 4 | Désactivation de la journalisation | Perte de traçabilité | SCP `deny-cloudtrail-tampering`, trail d'organisation avec validation des fichiers, bucket dans un compte séparé | Test 3 |
| 5 | Permissions excessives dans le temps | Surface d'attaque | Access Analyzer (accès inutilisé), politique issue de l'activité réelle, revues périodiques | Phase 4 |
| 6 | Compromission de l'IdP | Compromission de tous les comptes | Admin Keycloak non exposé (127.0.0.1 par défaut), sessions courtes, alertes ; **risque résiduel élevé en lab** (pas de HA, pas de durcissement production) | Section limites |
| 7 | Dérive de configuration | Écart non détecté | Terraform, scans CI (Checkov), Prowler | Test 9 |
| 8 | Usage détourné du break-glass | Accès admin permanent | MFA obligatoire, alerte à chaque usage, runbook | Test 10 |
| 9 | Fuite de secrets dans le dépôt | Compromission | `.gitignore`, gitleaks (pré-commit + CI), secret scanning GitHub | CI |
| 10 | Rôle CI trop puissant | Pivot depuis une PR | Trust limité à ce dépôt (PR et `main`), rôle lecture seule ; **limite** : il peut assumer `OrganizationAccountAccessRole` pour rafraîchir les comptes membres | Section limites |

Hypothèses : l'attaquant n'a pas accès physique à la machine Keycloak ; la messagerie des comptes membres est protégée.
