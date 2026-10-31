variable "name_prefix" {
  description = "Préfixe des ressources (inclure le nom du compte, ex: lab-dev)."
  type        = string
}

variable "alert_email" {
  type = string
}

variable "break_glass_user_name" {
  description = "Nom de l'utilisateur break-glass à surveiller (null = pas de règle)."
  type        = string
  default     = null
}
