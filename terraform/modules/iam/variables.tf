variable "name" {
  description = "Préfixe du nom du rôle"
  type        = string
}

variable "bucket_arn" {
  description = "ARN du bucket que le rôle peut lire"
  type        = string
}

variable "trusted_service" {
  description = "Service AWS autorisé à endosser le rôle"
  type        = string
  default     = "ec2.amazonaws.com"
}
