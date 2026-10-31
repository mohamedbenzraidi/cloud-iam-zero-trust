terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.80" }
  }
}

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  aws_service_access_principals = [
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "access-analyzer.amazonaws.com",
  ]

  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

resource "aws_organizations_account" "member" {
  for_each = var.accounts

  name                       = "${var.name_prefix}-${each.key}"
  email                      = each.value
  role_name                  = "OrganizationAccountAccessRole"
  parent_id                  = aws_organizations_organization.this.roots[0].id
  iam_user_access_to_billing = "DENY"
  close_on_deletion          = var.close_on_deletion

  lifecycle {
    # Ces attributs ne sont pas relisibles / modifiables après création.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
