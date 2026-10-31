variable "name_prefix" {
  type    = string
  default = "lab"
}

variable "home_region" {
  type    = string
  default = "eu-west-1"
}

variable "allowed_regions" {
  description = "Régions autorisées par la SCP. us-east-1 est requise (évènements IAM/console globaux)."
  type        = list(string)
  default     = ["eu-west-1", "us-east-1"]
}

variable "account_emails" {
  description = "E-mails UNIQUES des comptes membres (astuce: alias plus, ex. moi+lab-dev@gmail.com)."
  type        = map(string)
  validation {
    condition     = alltrue([for k in ["security", "dev", "prod"] : contains(keys(var.account_emails), k)])
    error_message = "account_emails doit contenir les clés security, dev et prod."
  }
}

variable "close_accounts_on_destroy" {
  description = "true = 'terraform destroy' ferme réellement les comptes membres."
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Adresse qui reçoit les alertes SNS (confirmation par lien requise)."
  type        = string
}

variable "enable_member_alerting" {
  description = "Déploie aussi les alertes dans security, dev et prod (en plus du compte de gestion)."
  type        = bool
  default     = true
}

variable "break_glass_user_name" {
  type    = string
  default = "break-glass"
}

variable "trail_retention_days" {
  type    = number
  default = 90
}

variable "enable_unused_access_analyzer" {
  description = "Analyseur d'accès inutilisé (payant par rôle/utilisateur analysé)."
  type        = bool
  default     = true
}

variable "developers_use_least_privilege" {
  description = "false = PowerUser-Dev (état 'avant') ; true = Developer-LeastPrivilege (état 'après')."
  type        = bool
  default     = false
}

variable "users" {
  description = "Utilisateurs de test (identiques à ceux créés dans Keycloak)."
  type = map(object({
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
    groups       = list(string)
  }))
}
