variable "region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Nom du projet, préfixe de toutes les ressources"
  type        = string
  default     = "devsecops-lab"
}

variable "owner" {
  description = "Responsable des ressources (tag Owner)"
  type        = string
  default     = "lab"
}

variable "github_repository" {
  description = "Dépôt GitHub autorisé à endosser les rôles, au format proprietaire/depot"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Format attendu : proprietaire/depot, sans joker."
  }
}

variable "budget_email" {
  description = "Adresse qui reçoit l'alerte de budget"
  type        = string
}

variable "budget_limit_usd" {
  description = "Montant mensuel du budget d'alerte, en dollars"
  type        = string
  default     = "1.0"
}

variable "offline" {
  description = "Valide ou planifie sans appeler AWS"
  type        = bool
  default     = false
}
