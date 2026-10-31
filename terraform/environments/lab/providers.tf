locals {
  tags = {
    Project   = "cloud-iam-zero-trust"
    ManagedBy = "terraform"
  }
  member_role = "OrganizationAccountAccessRole"
}

# Compte de gestion (home region)
provider "aws" {
  region = var.home_region
  default_tags { tags = local.tags }
}

# Compte de gestion (us-east-1 : évènements IAM / console globaux)
provider "aws" {
  alias  = "mgmt_use1"
  region = "us-east-1"
  default_tags { tags = local.tags }
}

# Comptes membres : alias résolus après la création des comptes (voir scripts/deploy.sh)
provider "aws" {
  alias  = "security"
  region = var.home_region
  assume_role {
    role_arn     = "arn:aws:iam::${module.organization.account_ids["security"]}:role/${local.member_role}"
    session_name = "terraform"
  }
  default_tags { tags = local.tags }
}

provider "aws" {
  alias  = "security_use1"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${module.organization.account_ids["security"]}:role/${local.member_role}"
    session_name = "terraform"
  }
  default_tags { tags = local.tags }
}

provider "aws" {
  alias  = "dev_use1"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${module.organization.account_ids["dev"]}:role/${local.member_role}"
    session_name = "terraform"
  }
  default_tags { tags = local.tags }
}

provider "aws" {
  alias  = "prod_use1"
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${module.organization.account_ids["prod"]}:role/${local.member_role}"
    session_name = "terraform"
  }
  default_tags { tags = local.tags }
}
