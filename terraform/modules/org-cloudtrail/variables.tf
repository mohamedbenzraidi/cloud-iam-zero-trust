variable "name_prefix" { type = string }
variable "region" {
  description = "Région d'origine du trail."
  type        = string
}
variable "trail_name" {
  type    = string
  default = "org-trail"
}
variable "organization_id" { type = string }
variable "management_account_id" { type = string }
variable "security_account_id" { type = string }
variable "retention_days" {
  type    = number
  default = 90
}
variable "force_destroy" {
  description = "Autorise terraform destroy à vider le bucket (laboratoire)."
  type        = bool
  default     = true
}
