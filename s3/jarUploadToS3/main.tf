terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "vamshi-dev-account"
}

variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-2"
}

variable "app_version" {
  description = "JAR version"
  default     = "1.4.2"
}

data "aws_caller_identity" "current" {}

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

resource "aws_s3_bucket" "app_artifacts" {
  bucket = "prod-product-service-artifacts-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.app_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.app_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "app_jar" {
  bucket = aws_s3_bucket.app_artifacts.id
  key    = "product-service/product-service-${var.app_version}.jar"
  source = "${path.module}/target/product-service-${var.app_version}.jar"
  etag   = filemd5("${path.module}/target/product-service-${var.app_version}.jar")
  tags   = local.common_tags
}