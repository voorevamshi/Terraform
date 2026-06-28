# ============================================================
#  main.tf — Product Service EC2 (Free-Tier / Test Production)
#  Region: ap-south-2 | Instance: t3.micro | AMI: Amazon Linux 2023
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------


# ------------------------------------------------
# Provider
# ------------------------------------------------------------
provider "aws" {
  region  = var.aws_region
  profile = "vamshi-dev-account"
}

# ============================================================
# VARIABLES
# ============================================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair to SSH into the instance"
  type        = string
  default     = "prod-product-service-key"
}

variable "your_ip_cidr" {
  description = "Your local machine public IP for SSH access (e.g. 203.0.113.10/32)"
  type        = string
  default     = "0.0.0.0/0" # Narrow this down to YOUR IP in real use
}

variable "app_version" {
  description = "Deployed application version — update on each release"
  type        = string
  default     = "1.4.2"
}


# ============================================================
# DATA SOURCES
# ============================================================

# Default VPC — free tier, no custom VPC needed for testing
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availabilityZone"
    values = ["ap-south-2a"]
  }
}

# ============================================================
# LOCAL VALUES — single source of truth for all tags
# ============================================================
locals {
  common_tags = {
    Name         = "prod-product-service-1"
    Environment  = "production"
    Application  = "product-service"
    Team         = "backend-team"
    CostCenter   = "CC-1042"
    Project      = "ecommerce-platform"
    Version      = var.app_version
    ManagedBy    = "terraform"
    Region       = var.aws_region
    AutoShutdown = "false"
  }
}
# ============================================================
# SECURITY GROUP
# ============================================================
resource "aws_security_group" "product_service_sg" {
  name        = "prod-product-service-sg"
  description = "Security group for product-service EC2"
  vpc_id      = data.aws_vpc.default.id

  # SSH — restricted to your IP only
  ingress {
    description = "SSH from your machine"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }

  # App port — open for testing (lock to ALB SG in real prod)
  ingress {
    description = "Spring Boot HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }

  # App port — open for testing (lock to ALB SG in real prod)
  ingress {
    description = "Testing nginx working locally"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]

  }
  # All outbound (needed for yum installs, AWS SDK calls)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.your_ip_cidr]
  }

  tags = merge(local.common_tags, {
    Name = "prod-product-service-sg"
  })
}


# Query AWS for the latest Amazon Linux 2023 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# ============================================================
# EC2 INSTANCE
# ============================================================
resource "aws_instance" "nginx_service" {
  ami           = data.aws_ami.latest_amazon_linux.id # Dynamically retrieves the ID
  instance_type = "t3.micro"

  # ----- Networking -----
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.product_service_sg.id]
  associate_public_ip_address = true # Needed for SSH & testing
  key_name                    = var.key_pair_name

  # ----- All tags -----
  tags = local.common_tags


  # ... other config ...
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF


}
