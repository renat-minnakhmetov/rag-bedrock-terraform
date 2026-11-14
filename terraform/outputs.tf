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

output "opensearch_collection_arn" {
  value = aws_opensearchserverless_collection.kb.arn
}

output "opensearch_collection_id" {
  value = aws_opensearchserverless_collection.kb.id
}

output "opensearch_collection_endpoint" {
  value = aws_opensearchserverless_collection.kb.collection_endpoint
}

output "opensearch_dashboard_endpoint" {
  value = try(aws_opensearchserverless_collection.kb.dashboard_endpoint, null)
}

output "vector_index_name" {
  value = local.index_name
}

output "collection_group_name" {
  value = aws_opensearchserverless_collection_group.kb.name
}