terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.80" }
  }
}

locals {
  policies_dir = "${path.module}/../../../policies/scp"

  policies = {
    "deny-cloudtrail-tampering" = {
      description = "Interdit de stopper, supprimer ou modifier CloudTrail."
      content     = file("${local.policies_dir}/deny-cloudtrail-tampering.json")
    }
    "deny-root-and-leave-org" = {
      description = "Interdit l'usage du root des comptes membres et la sortie de l'organisation."
      content     = file("${local.policies_dir}/deny-root-and-leave-org.json")
    }
    "deny-iam-users-and-keys" = {
      description = "Interdit les utilisateurs IAM locaux et les clés d'accès."
      content     = file("${local.policies_dir}/deny-iam-users-and-keys.json")
    }
    "restrict-regions" = {
      description = "Restreint l'usage aux régions autorisées."
      content     = templatefile("${local.policies_dir}/restrict-regions.json.tftpl", { regions = jsonencode(var.allowed_regions) })
    }
  }

  attachments = {
    for pair in setproduct(keys(local.policies), keys(var.targets)) :
    "${pair[0]}.${pair[1]}" => { policy = pair[0], target = pair[1] }
  }
}

resource "aws_organizations_policy" "this" {
  for_each = local.policies

  name        = each.key
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.content
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = local.attachments

  policy_id = aws_organizations_policy.this[each.value.policy].id
  target_id = var.targets[each.value.target]
}
