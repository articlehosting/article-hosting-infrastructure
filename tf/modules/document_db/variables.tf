variable "docdb_username" {
    type        = string
    description = "Master username for DocumentDB"
    default     = ""
}

variable "docdb_password" {
    type        = string
    description = "Master password for DocumentDB"
    default     = ""
}

variable "docdb_instance_count" {
    type        = string
    description = "Number of instances that will be created in DocumentDB cluster"
    default     = 1
}

variable "docdb_subnets" {
  description = "List of subnets coming from VPC module"
}

variable "docdb_allowed_ip" {
    description = "List of IP addresses with allowed access to Document DB"
    default     = ["193.33.93.43/32"]
}

variable "vpc_id" {
    type = string
}

variable "vpc_cidr" {
    type = string
    description = "VPC CIDR block to allow access from VPC to Document DB"
}