terraform {
  #############################################################
  ## AFTER RUNNING TERRAFORM APPLY (WITH LOCAL BACKEND)
  ## THIS CODE WILL BE UNCOMMENTED, AND THEN RERUN WITH
  ## TERRAFORM INIT TO SWITCH FROM LOCAL BACKEND TO REMOTE 
  ## AWS BACKEND
  #############################################################
  # backend "s3" {
  #   bucket         = "tf_cloud_state"        # REPLACE ACTUAL BUCKET NAME
  #   key            = "import-bootstrap/terraform.tfstate"
  #   region         = "eu-north-1"
  #   dynamodb_table = "terraform-state-locking"
  #   encrypt        = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "tf-cloud-state" # REPLACE WITH ACTUAL BUCKET NAME
  force_destroy = true             # allows non-empty bucket deletion.
}

# Enable Versioning on S3 Bucket
resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption on S3 Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_conf" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
