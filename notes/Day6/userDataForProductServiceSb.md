Below  `user_data` block is a **bootstrap script**. When you launch an EC2 instance, AWS runs this script automatically during the very first boot process. It transforms a "blank" virtual machine into a configured server ready to host your Java application.

Here is a breakdown of how it works:

### 1. The Header: Shell Safety

-   `#!/bin/bash`: Tells the system to execute this as a Bash script.
    
-   `set -euxo pipefail`: A critical setting for debugging. It forces the script to stop immediately if any command fails (`-e`), prints every command before executing it (`-x`), and ensures errors in piped commands are caught (`-o pipefail`).
    
-   `exec > /var/log/user-data.log 2>&1`: This captures everything—every `echo` statement and every error message—and saves it to `/var/log/user-data.log`. If your app doesn't start, this file is the first place you look.
    

### 2. Software Installation

-   **Update:** `dnf update -y` brings the OS packages up to date.
    
-   **Java 17:** `dnf install -y java-17-amazon-corretto` installs AWS's optimized version of the OpenJDK.
    

### 3. Setup Directories

-   It creates a structured environment for your application under `/opt/product-service/`.
    
-   `chown -R ec2-user:ec2-user`: It grants ownership of these folders to the `ec2-user`, ensuring your application has permission to read/write files and logs without needing `root` privileges.
    

### 4. Systemd: The "Process Manager"

This is the most important part. By creating a `.service` file in `/etc/systemd/system/`, you are telling the Linux operating system to treat your Spring Boot app like a professional service.

-   **`ExecStart`**: This command runs your application. Note the memory flags:
    
    -   `-Xms256m -Xmx768m`: Restricts the Java heap size. This is vital for `t3.micro` instances to prevent the app from consuming so much memory that the OS crashes the process (OOM Killer).
        
    -   `-XX:+HeapDumpOnOutOfMemoryError`: If the app crashes due to memory, it saves a snapshot so you can analyze why it crashed.
        
-   **`Restart=always`**: If your app crashes, Linux will automatically restart it after 10 seconds.
    
-   **Logging**: All console output is piped to a permanent log file (`/var/log/product-service/app.log`) instead of being lost in the void.
    

### Why use `user_data` instead of manual setup?

This approach follows **Infrastructure as Code (IaC)** principles.

-   **Consistency:** Every time Terraform creates a new server, it is configured identically.
    
-   **Automation:** You don't have to SSH into the machine and type these commands manually.
    
-   **Auto-Healing:** If you need to scale up to 10 instances, all 10 will arrive with the software installed and the service configured automatically.


```
# ----- User Data: Java 17 + app setup + systemd -----
  # NOTE: This runs ONCE on first boot.
  # To debug failures → SSH in and check: sudo cat /var/log/user-data.log
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail                    # exit on error, log every command
    exec > /var/log/user-data.log 2>&1    # redirect ALL output to log file

    echo "===== [1/6] System update ====="
    dnf update -y

    echo "===== [2/6] Install Java 17 (Corretto) ====="
    dnf install -y java-17-amazon-corretto

    echo "===== [3/6] Verify Java ====="
    java -version

    echo "===== [4/6] Create app directories ====="
    mkdir -p /opt/product-service/config
    mkdir -p /var/log/product-service
    chown -R ec2-user:ec2-user /opt/product-service /var/log/product-service

    echo "===== [5/6] Create systemd service ====="
    cat > /etc/systemd/system/product-service.service <<'UNIT'
    [Unit]
    Description=Product Service Spring Boot App
    After=network.target

    [Service]
    User=ec2-user
    WorkingDirectory=/opt/product-service
    ExecStart=/usr/bin/java \
      -Xms256m -Xmx768m \
      -XX:+UseG1GC \
      -XX:+HeapDumpOnOutOfMemoryError \
      -XX:HeapDumpPath=/var/log/product-service/heapdump.hprof \
      -Dspring.profiles.active=prod \
      -jar /opt/product-service/product-service.jar
    Restart=always
    RestartSec=10
    StandardOutput=append:/var/log/product-service/app.log
    StandardError=append:/var/log/product-service/app.log

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable product-service

    echo "===== [6/6] User Data completed successfully ====="
  EOF
  ```

**One warning:** In your script, you have a line referencing `/opt/product-service/product-service.jar`. **Terraform does not automatically upload your JAR file.** You must ensure that your JAR file exists at that path on the server—either by uploading it via an S3 download command within this same script or by using a tool like Ansible or a CI/CD pipeline to move the file there after the instance is created.
  
