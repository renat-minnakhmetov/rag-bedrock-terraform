variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name applied as a default tag."
  type        = string
  default     = "rag-bedrock"
}

variable "environment" {
  description = "Environment name applied as a default tag."
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "S3 bucket for Terraform state."
  type        = string
  default     = null
}
