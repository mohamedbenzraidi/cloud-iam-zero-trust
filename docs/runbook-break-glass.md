# Runbook : compte break-glass

**Objet** : retrouver un accès administrateur au compte de gestion si Keycloak ou Identity Center est indisponible.
Seule exception assumée à « aucun utilisateur IAM » : l'utilisateur `break-glass` (compte de gestion), créé par Terraform
sans mot de passe ni clé d'accès.

## Mise en service (une fois)
1. Connecté en administrateur, définir un mot de passe console long (gestionnaire de mots de passe) : IAM > Users > `break-glass` > Security credentials > Console password.
2. Enrôler un MFA (idéalement une clé FIDO/hardware ; sinon TOTP) : sans MFA, la politique `require-mfa` refuse toute action.
3. Stocker mot de passe et MFA séparément, hors ligne (deux personnes si possible).
4. Vérifier que l'abonnement SNS du compte de gestion est confirmé.
5. Tester l'alerte (voir test #10) puis documenter la date du test.

## Utilisation
1. Déclarer l'incident (qui, quand, pourquoi) **avant** de se connecter.
2. Se connecter avec l'utilisateur `break-glass` + MFA. L'alerte « Utilisation du compte break-glass » doit arriver : si ce n'est pas le cas, le noter dans l'incident.
3. Faire le strict nécessaire (restaurer l'accès SSO, corriger Keycloak ou Identity Center).
4. Se déconnecter.

## Après usage
1. Changer le mot de passe et ré-enrôler le MFA si compromis ou si l'enrôlement est partagé.
2. Relire les évènements CloudTrail de l'utilisateur (`userName = break-glass`) et joindre la revue au rapport d'incident.
3. Mettre à jour ce runbook avec les enseignements.

## Contrôles périodiques (trimestriels)
- Le MFA fonctionne, l'alerte arrive, aucune clé d'accès n'existe pour cet utilisateur.
