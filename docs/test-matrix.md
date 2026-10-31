# Matrice de tests

Compléter « Résultat obtenu » (OK / KO + date) et ajouter la capture dans `docs/images/`.

| # | Scénario | Procédure | Attendu | Obtenu | Preuve |
|---|----------|-----------|---------|--------|--------|
| 1 | Un développeur crée un utilisateur IAM | Se connecter en `bob` (dev) > `aws iam create-user --user-name test` | Refusé (SCP / politique explicite) | ☐ | `test-01.png` |
| 2 | Connexion sans second facteur | Première connexion d'un nouvel utilisateur : tenter de passer l'enrôlement OTP | Impossible de continuer | ☐ | `test-02.png` |
| 3 | Désactiver CloudTrail dans `dev` | En admin dans dev, créer un trail local de test puis `aws cloudtrail stop-logging` | Bloqué par la SCP | ☐ | `test-03.png` |
| 4 | Un auditeur écrit dans S3 | En `carol` : `aws s3 mb s3://test-<id>` | Refusé | ☐ | `test-04.png` |
| 5 | Utilisateur retiré du groupe | Retirer `dave` de `developers` (Terraform + Keycloak), rouvrir le portail | Perd l'accès à la nouvelle session (sessions actives jusqu'à expiration) | ☐ | `test-05.png` |
| 6 | Ressource hors régions autorisées | En admin dev : créer un bucket en `ap-southeast-1` | Bloqué par SCP | ☐ | `test-06.png` |
| 7 | Connexion root | Se connecter root sur un compte membre | Alerte reçue (e-mail SNS) | ☐ | `test-07.png` |
| 8 | Session administrateur après 1 h | Attendre 1 h avec `cloud-admins` | Session expirée | ☐ | `test-08.png` |
| 9 | CI avec politique trop permissive | PR ajoutant une politique `Action: "*", Resource: "*"` | Échec du scan Checkov | ☐ | `test-09.png` |
| 10 | Utilisation du break-glass | Connexion `break-glass` + MFA | Alerte reçue | ☐ | `test-10.png` |
| 11 | Création de rôle sans boundary (bonus) | En `bob` avec `Developer-LeastPrivilege` : `iam create-role` sans `--permissions-boundary` | Refusé | ☐ | `test-11.png` |

Notes : les alertes EventBridge/CloudTrail peuvent prendre quelques minutes. Le test 9 suppose que la règle interdisant `*:*` est active dans la version de Checkov utilisée.
