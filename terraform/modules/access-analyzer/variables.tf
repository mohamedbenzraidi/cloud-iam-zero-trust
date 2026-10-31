variable "name_prefix" { type = string }
variable "security_account_id" { type = string }
variable "enable_unused_access" {
  type    = bool
  default = true
}
variable "unused_access_age" {
  description = "Nombre de jours sans usage avant remontée d'un constat."
  type        = number
  default     = 90
}
