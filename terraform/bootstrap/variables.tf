variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "state_bucket_name" {
  description = "Nom GLOBALEMENT unique du bucket d'état (ex: lab-iam-tfstate-<account-id>)."
  type        = string
}

variable "github_repo" {
  description = "Dépôt GitHub autorisé à assumer le rôle, format owner/repo."
  type        = string
}
