variable "lambda_name_prefix" {
    type        = string
    default     = "hive-article-hosting-lambda"
}

variable "environment" {
    type        = string
}

variable "vpc_id" {
    description = "VPC id for Lambda"
}

variable "lambda_sec_group" {
    type        = string
    description = "Lambda Sec Group id to access DB"
}

variable "queue_arn" {
    type        = string
    description = "SQS queue ARN"
}

variable "lambda_vpc_access_policy_arn" {
    type        = string
    description = "ARN of AWS Managed policy for Lambda VPC Access"
    default     = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}