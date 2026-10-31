terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.80" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # IMPORTANT : les évènements IAM, de connexion console et root sont journalisés en us-east-1.
  # Ce module doit donc être déployé en us-east-1 pour chaque compte surveillé.
  rules = merge(
    {
      root-login = {
        description = "Connexion avec l'utilisateur root"
        pattern = {
          "detail-type" = ["AWS Console Sign In via CloudTrail"]
          detail        = { userIdentity = { type = ["Root"] }, eventName = ["ConsoleLogin"] }
        }
      }
      console-login-without-mfa = {
        description = "Connexion console d'un utilisateur IAM sans MFA"
        pattern = {
          "detail-type" = ["AWS Console Sign In via CloudTrail"]
          detail = {
            eventName           = ["ConsoleLogin"]
            userIdentity        = { type = ["IAMUser"] }
            additionalEventData = { MFAUsed = ["No"] }
            responseElements    = { ConsoleLogin = ["Success"] }
          }
        }
      }
      iam-user-created = {
        description = "Création d'utilisateur IAM, de clé d'accès ou de mot de passe console"
        pattern = {
          source        = ["aws.iam"]
          "detail-type" = ["AWS API Call via CloudTrail"]
          detail        = { eventSource = ["iam.amazonaws.com"], eventName = ["CreateUser", "CreateAccessKey", "CreateLoginProfile"] }
        }
      }
      iam-policy-changed = {
        description = "Modification de politique IAM ou de permissions boundary"
        pattern = {
          source        = ["aws.iam"]
          "detail-type" = ["AWS API Call via CloudTrail"]
          detail = {
            eventSource = ["iam.amazonaws.com"]
            eventName = [
              "CreatePolicy", "CreatePolicyVersion", "DeletePolicy", "DeletePolicyVersion", "SetDefaultPolicyVersion",
              "PutUserPolicy", "PutRolePolicy", "PutGroupPolicy",
              "AttachUserPolicy", "AttachRolePolicy", "AttachGroupPolicy",
              "DetachUserPolicy", "DetachRolePolicy", "DetachGroupPolicy",
              "PutRolePermissionsBoundary", "DeleteRolePermissionsBoundary",
              "PutUserPermissionsBoundary", "DeleteUserPermissionsBoundary",
            ]
          }
        }
      }
    },
    var.break_glass_user_name == null ? {} : {
      break-glass-used = {
        description = "Utilisation du compte break-glass"
        pattern     = { detail = { userIdentity = { userName = [var.break_glass_user_name] } } }
      }
    }
  )
}

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-security-alerts"
}

data "aws_iam_policy_document" "topic" {
  statement {
    sid       = "AllowEventBridgePublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.topic.json
}

# L'abonnement e-mail doit être confirmé manuellement via le lien reçu.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each      = local.rules
  name          = "${var.name_prefix}-${each.key}"
  description   = each.value.description
  event_pattern = jsonencode(each.value.pattern)
}

resource "aws_cloudwatch_event_target" "sns" {
  for_each = local.rules
  rule     = aws_cloudwatch_event_rule.this[each.key].name
  arn      = aws_sns_topic.alerts.arn
}
