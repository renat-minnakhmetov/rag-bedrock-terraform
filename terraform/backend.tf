terraform {
  backend "s3" {
    bucket       = "rag-bedrock-dev-tfstate-191518190829"
    key          = "rag-bedrock/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}