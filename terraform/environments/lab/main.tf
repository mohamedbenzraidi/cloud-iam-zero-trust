# ---------------- Phase 1 : landing zone ----------------
module "organization" {
  source = "../../modules/organization"

  name_prefix       = var.name_prefix
  accounts          = var.account_emails
  close_on_deletion = var.close_accounts_on_destroy
}

module "scp" {
  source = "../../modules/organizations-scp"

  allowed_regions = var.allowed_regions
  targets = {
    security = module.organization.account_ids["security"]
    dev      = module.organization.account_ids["dev"]
    prod     = module.organization.account_ids["prod"]
  }
}

module "org_cloudtrail" {
  source = "../../modules/org-cloudtrail"
  providers = {
    aws.management = aws
    aws.security   = aws.security
  }

  name_prefix           = var.name_prefix
  region                = var.home_region
  organization_id       = module.organization.organization_id
  management_account_id = module.organization.management_account_id
  security_account_id   = module.organization.account_ids["security"]
  retention_days        = var.trail_retention_days
}

# ---------------- Phase 3 / 4 : Identity Center ----------------
locals {
  all_account_ids = merge(module.organization.account_ids, { management = module.organization.management_account_id })

  developer_permission_set = var.developers_use_least_privilege ? "Developer-LeastPrivilege" : "PowerUser-Dev"

  assignments = [
    { group = "cloud-admins", account = "management", permission_set = "AdministratorAccess" },
    { group = "cloud-admins", account = "security", permission_set = "AdministratorAccess" },
    { group = "cloud-admins", account = "dev", permission_set = "AdministratorAccess" },
    { group = "cloud-admins", account = "prod", permission_set = "AdministratorAccess" },
    { group = "developers", account = "dev", permission_set = local.developer_permission_set },
    { group = "developers", account = "prod", permission_set = "ReadOnly-Audit" },
    { group = "auditors", account = "management", permission_set = "ReadOnly-Audit" },
    { group = "auditors", account = "security", permission_set = "ReadOnly-Audit" },
    { group = "auditors", account = "dev", permission_set = "ReadOnly-Audit" },
    { group = "auditors", account = "prod", permission_set = "ReadOnly-Audit" },
  ]
}

module "identity_center" {
  source = "../../modules/identity-center"

  groups      = ["cloud-admins", "developers", "auditors"]
  users       = var.users
  account_ids = local.all_account_ids
  assignments = local.assignments
}

# ---------------- Phase 4 : Access Analyzer ----------------
module "access_analyzer" {
  source = "../../modules/access-analyzer"
  providers = {
    aws.management = aws
    aws.security   = aws.security
  }

  name_prefix          = var.name_prefix
  security_account_id  = module.organization.account_ids["security"]
  enable_unused_access = var.enable_unused_access_analyzer
}

# Boundary appliquée aux rôles créés par les développeurs (compte dev ; IAM est global)
resource "aws_iam_policy" "developer_boundary" {
  provider    = aws.dev_use1
  name        = "developer-boundary"
  description = "Permissions boundary imposée aux rôles créés par les développeurs."
  policy      = file("${path.module}/../../../policies/boundaries/developer-boundary.json")
}

# ---------------- Phase 6 : détection ----------------
module "alerting_management" {
  source    = "../../modules/alerting"
  providers = { aws = aws.mgmt_use1 }

  name_prefix           = "${var.name_prefix}-mgmt"
  alert_email           = var.alert_email
  break_glass_user_name = var.break_glass_user_name
}

module "alerting_security" {
  count     = var.enable_member_alerting ? 1 : 0
  source    = "../../modules/alerting"
  providers = { aws = aws.security_use1 }

  name_prefix = "${var.name_prefix}-security"
  alert_email = var.alert_email
}

module "alerting_dev" {
  count     = var.enable_member_alerting ? 1 : 0
  source    = "../../modules/alerting"
  providers = { aws = aws.dev_use1 }

  name_prefix = "${var.name_prefix}-dev"
  alert_email = var.alert_email
}

module "alerting_prod" {
  count     = var.enable_member_alerting ? 1 : 0
  source    = "../../modules/alerting"
  providers = { aws = aws.prod_use1 }

  name_prefix = "${var.name_prefix}-prod"
  alert_email = var.alert_email
}
