variable "front_count" {
  description = "Nombre de serveurs web derrière le load balancer"
  type        = number
  default     = 2
}

variable "db_memory_mb" {
  description = "Limite mémoire de la base de données, en Mo"
  type        = number
  default     = 256
}

variable "db_password" {
  description = "Mot de passe de démonstration : ne jamais versionner un vrai secret"
  type        = string
  default     = "demo-hopla"
  sensitive   = true
}
