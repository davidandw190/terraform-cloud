# Web-App AWS Infrastrucure Terraform Configuration Demo

This configuration file sets up a common web application infrastructure on AWS, using resources such as:

- EC2 Instances,
- S3 Bucket,
- Load Balancer
- Security Groups
- Route 53 DNS Record
- PostgreSQL DB

It assumes that the S3 bucket and DynamoDB table for Terraform state management are already set up, as we did in `basics/basics/core-aws-backend`.
