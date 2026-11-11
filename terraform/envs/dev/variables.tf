variable "region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Nom du projet, utilisé comme préfixe et comme tag"
  type        = string
  default     = "devsecops-lab"
}

variable "owner" {
  description = "Responsable des ressources (tag Owner)"
  type        = string
  default     = "lab"
}

variable "offline" {
  description = "Planifie sans appeler AWS (aucun identifiant requis)"
  type        = bool
  default     = false
}

variable "app_ingress_cidrs" {
  description = "Plages autorisées à joindre l'application en HTTPS"
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "app_permissions_boundary_arn" {
  description = "Limite de permissions des rôles applicatifs, fournie par le bootstrap"
  type        = string
  default     = null
}
