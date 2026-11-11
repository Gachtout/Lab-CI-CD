variable "name" {
  description = "Préfixe de nom des ressources réseau"
  type        = string
}

variable "cidr" {
  description = "Plage d'adresses du VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zone" {
  description = "Zone de disponibilité du sous-réseau privé"
  type        = string
}
