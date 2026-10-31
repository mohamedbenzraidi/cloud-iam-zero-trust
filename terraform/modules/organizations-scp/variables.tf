variable "allowed_regions" {
  description = "Régions autorisées. Garder us-east-1 : les évènements IAM/console y sont journalisés."
  type        = list(string)
}

variable "targets" {
  description = "Map nom => ID de cible (compte ou OU) auquel attacher les SCP. Le compte de gestion n'est jamais affecté par les SCP."
  type        = map(string)
}
