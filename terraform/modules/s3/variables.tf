variable "name" {
  description = "Préfixe du nom du bucket (un suffixe unique est ajouté par AWS)"
  type        = string
}

variable "block_public_access" {
  description = "Active les quatre réglages de blocage de l'accès public"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Autorise la suppression du bucket même s'il contient des objets (utile pour un lab)"
  type        = bool
  default     = false
}
