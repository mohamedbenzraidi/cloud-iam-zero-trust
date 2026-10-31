# Seule exception volontaire à "aucun utilisateur IAM" : un compte de secours dans le compte de gestion
# (les SCP ne s'appliquent pas au compte de gestion). Aucun mot de passe ni clé n'est créé par Terraform :
# suivre docs/runbook-break-glass.md. Toute activité de cet utilisateur déclenche une alerte.
resource "aws_iam_user" "break_glass" {
  name = var.break_glass_user_name
  path = "/emergency/"
}

resource "aws_iam_user_policy_attachment" "break_glass_admin" {
  user       = aws_iam_user.break_glass.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Aucune action (hors enrôlement MFA) sans MFA.
resource "aws_iam_user_policy" "break_glass_require_mfa" {
  name   = "require-mfa"
  user   = aws_iam_user.break_glass.name
  policy = file("${path.module}/../../../policies/break-glass/require-mfa.json")
}
