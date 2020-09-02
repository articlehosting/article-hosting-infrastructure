variable "import_bucket_name" {
    type        = string
    description = "S3 bucket name for import"
    default     = "hive-article-hosting-import"
}

variable "environment" {
    type        = string
}

variable "sqs_name" {
    type        = string
    description = "Queue name"
    default     = "hive-article-hosting-sqs"
}