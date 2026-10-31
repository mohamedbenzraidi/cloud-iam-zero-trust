variable "groups" {
  description = "Groupes métier (identiques à ceux de Keycloak)."
  type        = list(string)
}

variable "users" {
  description = "Utilisateurs de test. L'email sert de user_name et doit être celui de Keycloak."
  type = map(object({
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
    groups       = list(string)
  }))
}

variable "account_ids" {
  description = "Map nom => ID de compte (security, dev, prod, management)."
  type        = map(string)
}

variable "assignments" {
  description = "Liste d'affectations {group, account, permission_set}."
  type = list(object({
    group          = string
    account        = string
    permission_set = string
  }))
}
