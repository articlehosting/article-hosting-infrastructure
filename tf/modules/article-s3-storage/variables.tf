variable "bucket_name" {
  type        = string
  description = "Source Bucket name for cantaloupe"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Region where to create bucket"
}
