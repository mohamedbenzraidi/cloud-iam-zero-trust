variable "name_prefix" {
  description = "Préfixe des noms de comptes (ex: lab -> lab-security)."
  type        = string
}

variable "accounts" {
  description = "Map nom court => e-mail unique du compte membre (ex: security, dev, prod)."
  type        = map(string)
}

variable "close_on_deletion" {
  description = "Si true, 'terraform destroy' FERME réellement les comptes membres (irréversible après 90 jours)."
  type        = bool
  default     = false
}
