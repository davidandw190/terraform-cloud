# Core AWS Backend Terraform Configuration File

This Terraform configuration file sets up, in a simple manner, the necessary AWS resources to enable remote state management for TF. It uses S3 for state storage and DynamoDB for state locking, and it ensures the reliability and security of your Terraform state.

## Features:
- **S3 Bucket Creation**: Creates an S3 bucket to store the Terraform state file.
- **Bucket Versioning**: Enables versioning on the S3 bucket to keep track of changes to the state file.
- **Server-Side Encryption**: Configures server-side encryption for the S3 bucket to secure the state file.
- **DynamoDB Table**: Creates a DynamoDB table for state locking to prevent concurrent operations, ensuring safe state management.

## Steps:

1. **Initial Setup with Local Backend**:
   - Run `terraform init` to initialize the configuration with a local backend.
   - Run `terraform apply` to create the AWS resources (S3 bucket and DynamoDB table).

2. **Configure Remote Backend**:
   - Uncomment the `backend "s3"` block in the `main.tf` file.
   - Replace placeholder values (e.g., bucket name) with actual values.

3. **Switch to Remote Backend**:
   - Run `terraform init` again to reinitialize the configuration with the remote backend.
   - This step migrates the state file to the S3 bucket and enables state locking with DynamoDB.
