**Automated Artifact Deployment: Managing S3 Buckets, Versioning, and Local File Uploads**

### 🎯 Learning Objectives

-   Understand how to dynamically name resources using `data` sources (AWS Account ID).
    
-   Learn the importance of **Public Access Blocks** for S3 security.
    
-   Master the `aws_s3_object` resource for uploading local build artifacts to the cloud.
    
-   Understand the `etag` attribute and its role in tracking file changes.

### Session Summary

This session focuses on the "CI/CD-like" capability of Terraform: taking a compiled JAR file from your local machine and uploading it to a secured, versioned S3 bucket. We used the `aws_caller_identity` data source to ensure globally unique bucket naming and applied security best practices by blocking all public access to your artifacts.

### 1. Analysis of the S3 Artifact Configuration

| Resource / Block | Role |  
|---|---|  
| **`data "aws_caller_identity"`** | Fetches the current AWS Account ID to ensure the S3 bucket name is globally unique. |  
| **`aws_s3_bucket`** | Creates the Amazon S3 bucket that stores application artifacts. The bucket name typically includes the AWS Account ID to avoid naming conflicts. |  
| **`aws_s3_bucket_versioning`** | Enables object versioning, allowing previous JAR versions to be retained and restored when needed. Essential for rollback strategies. |  
| **`aws_s3_bucket_public_access_block`** | Implements security best practices by blocking all public access to the bucket, ensuring application artifacts are never exposed to the public internet. |  
| **`aws_s3_object`** | Uploads the local JAR file (or other deployment artifact) from the local machine to the S3 bucket. |  
| **`etag = filemd5(...)`** | Calculates the MD5 checksum of the local file. Terraform re-uploads the object only when the file content changes, avoiding unnecessary uploads. |

### 2. Troubleshooting & Configuration Corrections

#### **Fixing Your Path Issue**

Your local JAR file path is `E:\JavaProjects\OthersGit\LoadTesting\product-service\target\product-service.jar`.

However, your `aws_s3_object` resource is currently looking for a file that matches your `var.app_version`. You must ensure your local file matches the path string in your configuration exactly.

**Update your `aws_s3_object` resource:**
```
resource "aws_s3_object" "app_jar" {
  bucket = aws_s3_bucket.app_artifacts.id
  key    = "product-service/product-service-${var.app_version}.jar"
  
  # Ensure this matches your ACTUAL path exactly
  source = "E:/JavaProjects/OthersGit/LoadTesting/product-service/target/product-service-${var.app_version}.jar"
  
  etag   = filemd5("E:/JavaProjects/OthersGit/LoadTesting/product-service/target/product-service-${var.app_version}.jar")
  tags   = local.common_tags
}
```
_Note: Use forward slashes `/` in your Terraform file paths, even on Windows, to avoid escape character issues._

### 3. Professional Considerations

-   **The `profile` argument:** You defined `profile = "vamshi-dev-account"` in your provider block. This is excellent! It tells Terraform to look for credentials in your `~/.aws/credentials` (or Windows `%USERPROFILE%\.aws\credentials`) file under that specific profile header.
    
-   **Security (Public Access Block):** You have implemented the "Block All Public Access" settings. This is a **best practice** for any artifact storage. Never store code/JARs in a public bucket.

### ⭐ Key Exam Topics Covered

-   **`etag` / `filemd5`**: Terraform uses MD5 hashes to detect file changes. If the hash changes, Terraform updates the object; if not, it does nothing.
    
-   **Global Namespace:** S3 bucket names must be unique globally. Using `data.aws_caller_identity.current.account_id` is a classic exam-style strategy to ensure bucket name uniqueness without hardcoding.
    
-   **Lifecycle:** `aws_s3_object` is managed as part of the state. If you delete the object resource from your `main.tf`, Terraform will remove the file from S3.
    

### 🎯 Key Interview Topics Covered

-   **"How do you ensure your infrastructure is secure?"** (Answer: Mention `aws_s3_bucket_public_access_block`—it prevents accidental exposure of sensitive JAR files).
    
-   **"How do you handle local file uploads in Terraform?"** (Answer: Using `aws_s3_object` with `filemd5` for change detection).
