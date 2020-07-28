variable "namespace" {
  type        = string
  description = "Kubernetes namespace, e.g. default"
  default     = "default"
}

variable "mongo_db_name" {
  type        = string
  description = "Mongo DB custom name"
  default     = "hosting"
}

variable "mongo_username" {
  type        = string
  description = "Mongo DB username for custom DB"
}

variable "mongo_password" {
  type        = string
  description = "Mongo DB password for custom DB"
}

