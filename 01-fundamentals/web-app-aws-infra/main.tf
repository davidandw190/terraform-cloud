terraform {
  # Assumes s3 bucket and dynamo DB table already set up
  # See /fundamentals/core-aws-backend
  backend "s3" {
    bucket         = "tf_cloud_state" # REPLACE ACTUAL BUCKET NAME
    key            = "web-app-aws-infra/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

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


# EC2 Instances Configuration
resource "aws_instance" "instance_1" {
  ami             = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS // eu-north-1
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              echo "Hello, World! from AWS EC2 Instance 1" > index.html
              python3 -m http.server 8080 &
              EOF
}

resource "aws_instance" "instance_2" {
  ami             = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS // eu-north-1
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt upgrade -y
              echo "Hello, World! from AWS EC2 Instance 2" > index.html
              python3 -m http.server 8080 &
              EOF
}

# S3 Bucket Configuration
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "web-app-aws-infra"
  force_destroy = true # Force bucket deletion even if it contains objects
}

# S3 Bucket Versioning Configuration
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled" # Enable versioning for the bucket
  }
}

# S3 Bucket Server-Side Encryption Configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Use AES-256 encryption for the bucket
    }
  }
}

# Data Sources for VPC and Subnets
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

# Security Group for EC2 Instances
resource "aws_security_group" "instances" {
  name = "instance-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id
  from_port         = 8080 # Allow inbound traffic on port 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Allow traffic from all IPs
}

# Load Balancer Configuration
resource "aws_lb" "load_balancer" {
  name               = "web-app-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404 # Default action for the listener
    }
  }
}

resource "aws_lb_target_group" "instances" {
  name     = "example-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id
  health_check {
    path                = "/" # Health check path
    protocol            = "HTTP"
    matcher             = "200" # Expected response code for health checks
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_1.id
  port             = 8080 # Attach instance_1 to the target group
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_2.id
  port             = 8080 # Attach instance_2 to the target group
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn # Forward traffic to the target group
  }
}

# Route 53 DNS Configuration
resource "aws_route53_zone" "primary" {
  name = "first-deployment.com"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "first-deployment.com"
  type    = "A"
  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}

# RDS PostgreSQL Database Configuration
resource "aws_db_instance" "db_instance" {
  allocated_storage          = 20 # Storage size in GB
  auto_minor_version_upgrade = true
  storage_type               = "standard"
  engine                     = "postgres"
  engine_version             = "12"
  instance_class             = "db.t2.micro"
  username                   = "foo"
  password                   = "foobarbaz"
  skip_final_snapshot        = true
}
