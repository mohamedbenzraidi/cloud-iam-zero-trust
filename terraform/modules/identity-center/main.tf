terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.80" }
  }
}

# IAM Identity Center doit être activé manuellement une fois (console), voir docs/deployment-guide.md.
data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  policies_dir      = "${path.module}/../../../policies/permission-sets"

  permission_sets = {
    "AdministratorAccess" = {
      description      = "Administrateur complet, session courte (1 h)."
      session_duration = "PT1H"
      managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      inline_policy    = null
      boundary         = null
    }
    "PowerUser-Dev" = {
      description      = "PowerUser limité : pas d'utilisateur IAM, régions autorisées uniquement."
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      inline_policy    = file("${local.policies_dir}/poweruser-dev-guardrails.json")
      boundary         = null
    }
    "ReadOnly-Audit" = {
      description      = "Lecture seule et audit de sécurité."
      session_duration = "PT4H"
      managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess", "arn:aws:iam::aws:policy/SecurityAudit"]
      inline_policy    = null
      boundary         = null
    }
    "Developer-LeastPrivilege" = {
      description      = "Développeur au moindre privilège (politique issue d'Access Analyzer) avec boundary."
      session_duration = "PT4H"
      managed_policies = []
      inline_policy    = file("${local.policies_dir}/developer-least-privilege.json")
      boundary         = "arn:aws:iam::aws:policy/PowerUserAccess"
    }
  }

  managed_attachments = merge([
    for ps, cfg in local.permission_sets : {
      for arn in cfg.managed_policies : "${ps}|${arn}" => { permission_set = ps, arn = arn }
    }
  ]...)

  memberships = {
    for pair in flatten([
      for uname, u in var.users : [
        for g in u.groups : { key = "${uname}|${g}", user = uname, group = g }
      ]
    ]) : pair.key => pair
  }
}

# ---------- Utilisateurs et groupes (provisionnement manuel, pas de SCIM avec Keycloak) ----------
resource "aws_identitystore_group" "this" {
  for_each          = toset(var.groups)
  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = "Groupe ${each.key} (reflète le groupe Keycloak du même nom)"
}

resource "aws_identitystore_user" "this" {
  for_each          = var.users
  identity_store_id = local.identity_store_id
  user_name         = each.value.email # doit correspondre au NameID SAML envoyé par Keycloak (email)
  display_name      = each.value.display_name

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

resource "aws_identitystore_group_membership" "this" {
  for_each          = local.memberships
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  member_id         = aws_identitystore_user.this[each.value.user].user_id
}

# ---------- Permission sets ----------
resource "aws_ssoadmin_permission_set" "this" {
  for_each         = local.permission_sets
  name             = each.key
  description      = each.value.description
  instance_arn     = local.instance_arn
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = local.managed_attachments
  instance_arn       = local.instance_arn
  managed_policy_arn = each.value.arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each           = { for k, v in local.permission_sets : k => v if v.inline_policy != null }
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  inline_policy      = each.value.inline_policy
}

resource "aws_ssoadmin_permissions_boundary_attachment" "this" {
  for_each           = { for k, v in local.permission_sets : k => v if v.boundary != null }
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn

  permissions_boundary {
    managed_policy_arn = each.value.boundary
  }
}

# ---------- Affectations groupe x compte x permission set ----------
resource "aws_ssoadmin_account_assignment" "this" {
  for_each = { for a in var.assignments : "${a.group}|${a.account}|${a.permission_set}" => a }

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  principal_id       = aws_identitystore_group.this[each.value.group].group_id
  principal_type     = "GROUP"
  target_id          = var.account_ids[each.value.account]
  target_type        = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_managed_policy_attachment.this,
    aws_ssoadmin_permission_set_inline_policy.this,
    aws_ssoadmin_permissions_boundary_attachment.this,
  ]
}
