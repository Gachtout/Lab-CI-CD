variable "name" {
  description = "Nom du security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC dans lequel créer le security group"
  type        = string
}

variable "ingress_cidrs" {
  description = "Plages autorisées à joindre l'application en HTTPS"
  type        = list(string)
}

variable "egress_cidr" {
  description = "Plage que l'application peut joindre en HTTPS"
  type        = string
}
