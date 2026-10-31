terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.80"
      configuration_aliases = [aws.management, aws.security]
    }
  }
}

# Le compte security devient administrateur délégué d'Access Analyzer.
resource "aws_organizations_delegated_administrator" "this" {
  provider          = aws.management
  account_id        = var.security_account_id
  service_principal = "access-analyzer.amazonaws.com"
}

# Accès externe (public / inter-organisation) sur toute l'organisation.
resource "aws_accessanalyzer_analyzer" "external" {
  provider      = aws.security
  analyzer_name = "${var.name_prefix}-org-external-access"
  type          = "ORGANIZATION"

  depends_on = [aws_organizations_delegated_administrator.this]
}

# Accès inutilisé (payant : tarification par rôle/utilisateur IAM analysé).
resource "aws_accessanalyzer_analyzer" "unused" {
  count         = var.enable_unused_access ? 1 : 0
  provider      = aws.security
  analyzer_name = "${var.name_prefix}-org-unused-access"
  type          = "ORGANIZATION_UNUSED_ACCESS"

  configuration {
    unused_access {
      unused_access_age = var.unused_access_age
    }
  }

  depends_on = [aws_organizations_delegated_administrator.this]
}
