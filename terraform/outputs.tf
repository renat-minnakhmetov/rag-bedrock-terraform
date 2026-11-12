output "state_bucket_name" {
  description = "S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_lock_table_name" {
  description = "DynamoDB table used to lock Terraform state."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "terraform_backend_config" {
  description = "Backend block to add after the first apply, then run terraform init -migrate-state."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "${var.project_name}/${var.environment}/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }
  EOT
}
