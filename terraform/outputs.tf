output "documents_bucket_name" {
  description = "S3 bucket that stores documents for Bedrock."
  value       = aws_s3_bucket.documents.id
}

output "state_bucket_name" {
  description = "S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_backend_config" {
  description = "S3 backend block. Locking uses a lock file in the state bucket."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.terraform_state.id}"
        key          = "${var.project_name}/${var.environment}/terraform.tfstate"
        region       = "${var.aws_region}"
        encrypt      = true
        use_lockfile = true
      }
    }
  EOT
}

output "bedrock_kb_role_arn" {
  description = "IAM role ARN for Amazon Bedrock Knowledge Base"
  value       = aws_iam_role.bedrock_kb.arn
}

output "bedrock_kb_role_name" {
  description = "IAM role name"
  value       = aws_iam_role.bedrock_kb.name
}