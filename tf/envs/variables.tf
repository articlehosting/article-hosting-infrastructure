variable "region" {
  type        = string
  default     = "us-east-1"
  description = "Deployment region for the environment"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "domain_name" {
  type        = string
  description = "Root domain name for the environment"
}

variable "map_users" {
  default = [
    {
      userarn  = "arn:aws:iam::540790251273:user/GiorgioSironi"
      username = "GiorgioSironi"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::540790251273:user/GlebGodonoga"
      username = "GlebGodonoga"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::540790251273:user/GithubActions"
      username = "GithubActions"
      groups   = ["system:masters"]
    },
  ]
  description = "IAM users that can access the cluster"
}
