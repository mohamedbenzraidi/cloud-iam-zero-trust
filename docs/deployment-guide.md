# Guide de déploiement pas à pas

Ordre exact, avec les étapes manuelles. Durée : environ 1 journée la première fois.

## 0. Préparation
1. Créer un compte AWS dédié, activer le MFA sur le root, ne plus l'utiliser (créer un administrateur IAM temporaire
   pour lancer Terraform, ou utiliser `aws configure sso` si Identity Center existe déjà).
2. Configurer AWS Budgets (1 $, 5 $, 10 $).
3. Installer Terraform ≥ 1.10, AWS CLI v2, Docker, Prowler (`pip install prowler`).
4. Préparer 4 adresses e-mail uniques (3 comptes membres + alertes). Les alias `moi+lab-dev@domaine.tld` fonctionnent.

## 1. Bootstrap (état distant + OIDC GitHub)
```bash
cd terraform/bootstrap
terraform init
terraform apply -var state_bucket_name=lab-iam-tfstate-<ID_COMPTE> -var github_repo=<owner>/<repo>
```
Noter `state_bucket` et `ci_role_arn`. Ajouter dans GitHub (Settings > Variables) : `AWS_CI_ROLE_ARN`, `TF_STATE_BUCKET`, `AWS_REGION`,
et en secrets : `TF_VAR_ACCOUNT_EMAILS`, `TF_VAR_ALERT_EMAIL`, `TF_VAR_USERS` (JSON).

## 2. Activer IAM Identity Center (manuel, une fois)
Console AWS > IAM Identity Center > **Enable** (région `eu-west-1`, créer l'organisation si demandé : l'organisation existante sera alors à importer, voir Dépannage).

## 3. Keycloak
```bash
cd idp/keycloak && cp .env.example .env   # éditer les mots de passe
docker compose up -d
```
Console : http://localhost:8080 (admin). Le realm `lab`, les groupes et l'OTP obligatoire sont importés.
Créer les utilisateurs de test (mots de passe temporaires affichés) :
```bash
EMAIL_DOMAIN=example.com KEYCLOAK_ADMIN_PASSWORD=<...> ./scripts/create-test-users.sh
```

## 4. Infrastructure AWS
```bash
cd terraform/environments/lab
cp terraform.tfvars.example terraform.tfvars   # adapter e-mails et utilisateurs
cp backend.hcl.example backend.hcl             # adapter le bucket d'état
cd ../../..
./scripts/deploy.sh apply
```
Le script déploie d'abord l'organisation et les comptes (les providers des comptes membres en dépendent), puis tout le reste.
Les nouveaux comptes peuvent mettre quelques minutes à être utilisables : relancer `terraform apply` si une erreur d'assume-role apparaît.
Confirmer les e-mails d'abonnement SNS reçus (un par compte).

## 5. Fédération SAML (manuel)
1. Identity Center > Settings > **Change identity source** > *External identity provider*.
2. Noter l'**URL ACS** et l'**URL de l'émetteur** affichées.
3. Créer le client SAML dans Keycloak :
   ```bash
   ACS_URL=<...> ISSUER_URL=<...> KEYCLOAK_ADMIN_PASSWORD=<...> ./scripts/configure-aws-saml-client.sh
   ```
4. Télécharger les métadonnées `http(s)://<hôte>/realms/lab/protocol/saml/descriptor` et les importer dans Identity Center.
   Si Identity Center refuse une URL HTTP, utiliser le mode HTTPS (`docker-compose.https.yml`, domaine requis).
5. Vérifier que les utilisateurs, groupes et affectations créés par Terraform sont toujours présents après le changement de source.
6. Tester : portail SSO > Keycloak > mot de passe temporaire + enrôlement OTP > choix du compte et du rôle.

## 6. Break-glass
Suivre `runbook-break-glass.md`.

## 7. Audit avant / après
```bash
AWS_PROFILE=<profil-auditeur> ./scripts/run-prowler.sh before
# corriger, puis passer developers_use_least_privilege = true, apply
AWS_PROFILE=<profil-auditeur> ./scripts/run-prowler.sh after
```

## 8. Tests et preuves
Dérouler `test-matrix.md` et compléter les colonnes « obtenu » et « preuve ».

## Dépannage
- **Organisation déjà existante** (créée par l'activation d'Identity Center) : `terraform import module.organization.aws_organizations_organization.this <o-xxxx>`.
- **`Invalid provider configuration` au plan** : l'étape 1 de `deploy.sh apply` n'a pas encore créé les comptes.
- **Limite de comptes** : un compte récent peut être limité à quelques comptes membres ; demander une hausse au support AWS.
- **Destruction** : les comptes membres ne sont fermés que si `close_accounts_on_destroy = true` ; sinon les retirer de l'organisation / les fermer manuellement (quotas de fermeture : voir la doc AWS Organizations).
