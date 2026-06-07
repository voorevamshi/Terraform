### Advanced Resource Configuration: Custom Validation, Timeouts, and Syntax Debugging

### 🎯 Learning Objectives

-   Learn how to implement `custom_condition` blocks for infrastructure validation.
-   Understand `timeouts` blocks for handling slow resource provisioning.
-   Correct common syntax errors in HCL resource blocks.
-   Master the correct naming conventions for resources.

### 📝 Session Summary

This session focuses on defensive infrastructure coding. We explored how to use **Custom Conditions** to enforce business logic (e.g., ensuring an instance is the correct type) and **Timeouts** to handle API latency. We also cleaned up your provided code snippets, fixing naming convention violations and syntax errors in `aws_instance` and `aws_s3_bucket_versioning` configurations.

### ⭐ Key Exam Topics Covered

-   **Custom Conditions:** Using `lifecycle { precondition { ... } }` and `postcondition` blocks to validate inputs.
    
-   **Timeouts:** Configuring `create`, `update`, and `delete` timeouts to manage long-running operations.
    
-   **HCL Syntax:** Resource labels cannot contain spaces; valid naming requires underscores.
    
-   **Dependency Management:** Referencing resources via their logical names correctly.
    

### 🎯 Key Interview Topics Covered

-   **Defensive IaC:** "How do you ensure your code doesn't deploy non-compliant infrastructure?" (Answer: Custom Conditions/Policies).
    
-   **API Latency:** "What do you do if a resource takes too long to provision?" (Answer: Use `timeouts` blocks to override defaults).
    

### Corrected & Enhanced Notes

#### **1. Custom Conditions**

Used to validate the state of your infrastructure during `plan` or `apply`.

Terraform

```
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  lifecycle {
    precondition {
      condition     = var.instance_type == "t3.micro"
      error_message = "Only t3.micro is allowed for cost optimization."
    }
  }
}

```

#### **2. Operation Timeouts**

Use this to prevent Terraform from timing out if a cloud resource is slow to respond.

Terraform

```
resource "aws_db_instance" "db" {
  # ...
  timeouts {
    create = "60m"
    delete = "2h"
  }
}

```

### Corrected Code Snippets

#### **Fixing the S3 Configuration**

_Note: Removed extra braces and fixed the resource label._

Terraform

```
resource "aws_s3_bucket" "example" {
  bucket = "cloud-aws-bucket1"

  tags = {
    Name        = "My bucket"
    Environment = "Developer"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

```

#### **Fixing the EC2 Configuration**

_Note: The `subnet_id` argument was missing the assignment operator (`=`) and the resource name contained an invalid space._

Terraform

```
resource "aws_instance" "app_server" {
  count           = 1
  ami             = "ami-05ffe3c48a9991133"
  instance_type   = "t2.micro"
  subnet_id       = "subnet-09486d7f7787897bc"
  security_groups = ["sg-06498a8087dc650ab"]
  key_name        = "sathya"

  tags = {
    Name = "My server"
  }
}

```

### Mistakes / Corrections Found

-   **Syntax Error (Spaces):** `resource "aws_s3_bucket_versioning" "versioning example"` is illegal. Changed to `versioning_example`.
    
-   **Missing Assignment:** In your `aws_instance` code, you had `"subnet_id" subnet_id` syntax. In HCL, it must be `argument_name = value`.
    
-   **Structure:** You had `versioning configuration` (missing underscore). It must be `versioning_configuration`.
    

### Discussion Points / Clarifications Needed

-   **Condition Logic:** Preconditions happen _before_ the action (checking variables), while Postconditions check the _result_ of the creation. Do you see why Preconditions are better for catching bad input before talking to AWS?
    

### ## Terraform Associate Exam Focus Areas

-   **Resource Labels:** Must not contain spaces.
    
-   **Implicit Dependencies:** Referencing `aws_s3_bucket.example.id` inside the `aws_s3_bucket_versioning` block creates an implicit dependency, ensuring the bucket exists first.
    
-   **Timeouts:** Remember that timeouts are provided by the **Provider**, not the Terraform Core.
    

**Would you like to move on to Day 4, covering "Variables and Outputs," or should we practice writing a Custom Condition?**
