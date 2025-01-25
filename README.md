# Terraform Project: Cloud Infrastructure

This repository contains the files required to deploy and manage cloud infrastructure using Terraform. The structure is organized into modules and directories based on different system components, such as networks, web services, databases, and Lambda functions.

<img width="1128" alt="image" src="https://github.com/user-attachments/assets/39331966-bd3e-4669-ab4b-8689cc24f8c5" />

## Repository Structure

```
├── ec2
│   ├── loadbalancer.tf          # Load balancer configuration
│   ├── mage.tf                  # Mage instance configuration
│   ├── mongo.tf                 # MongoDB database configuration
│   ├── neo4j.tf                 # Neo4j database configuration
│   ├── output.tf                # Outputs related to EC2 instances
│   ├── scrapper.tf              # Scraper configuration
│   └── variables.tf             # Variables used in the EC2 module
├── lambda
│   ├── lambda_neo4j_query.tf    # Lambda configuration for querying Neo4j
│   ├── lambda_s3.tf             # Lambda configuration for interacting with S3
│   ├── output.tf                # Outputs related to Lambda functions
│   ├── src                      # Source code for Lambda functions
│   │   ├── neo
│   │   │   ├── Neo4jDataBaseHandler.py    # Neo4j database handler
│   │   │   ├── neo_lambda_function.zip   # Compressed package for Neo4j Lambda
│   │   │   └── neo_lambda_handler.py     # Handler for the Neo4j Lambda function
│   │   └── s3
│   │       ├── s3_lambda_function.zip    # Compressed package for S3 Lambda
│   │       └── s3_lambda_handler.py      # Handler for the S3 Lambda function
│   └── variables.tf             # Variables used in the Lambda module
├── metrics
│   ├── ssh.tf                   # SSH monitoring configuration
│   ├── tests_and_reports.tf     # Test and report configuration
│   └── variables.tf             # Variables related to metrics
├── network
│   ├── network.tf               # Network configuration
│   └── output.tf                # Outputs related to the network
├── s3
│   ├── conf
│   │   ├── locustfile.py        # Load testing configuration with Locust
│   │   ├── mongod.conf          # MongoDB configuration
│   │   ├── neo4j.conf           # Neo4j configuration
│   │   └── prometheus.yml       # Prometheus configuration
│   ├── nginx
│   │   ├── Dockerfile           # Dockerfile for Nginx container
│   │   └── nginx.conf           # Nginx configuration file
│   ├── s3.tf                    # S3 service configuration
│   └── variables.tf             # Variables used in the S3 module
├── webservice
│    ├── output.tf                # Outputs related to the web service
│    ├── ssh.tf                   # SSH access configuration
│    ├── variables.tf             # Variables used in the web service module
│    └── webservice.tf            # Web service configuration
├── provider.tf                  # Terraform provider configuration
├── README.md                    # Project documentation
└── variables.tf                 # Global project variables
```

## Prerequisites

1. **Terraform**: Ensure Terraform is installed. [Installation instructions](https://www.terraform.io/downloads).
2. **Cloud Provider**: This project is designed for AWS.
3. **Credentials**: Configure AWS credentials for Terraform. Ensure your AWS credentials are stored properly in the `~/.aws/credentials` file:

   ### For Linux/MacOS:
   The file should look like this:
   ```ini
   [default]
   aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
   aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
   ```

   ### For Windows:
   Use the path `%USERPROFILE%\.aws\credentials` and structure it similarly:
   ```ini
   [default]
   aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
   aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
   ```

   Replace `YOUR_AWS_ACCESS_KEY_ID` and `YOUR_AWS_SECRET_ACCESS_KEY` with your actual AWS credentials.

## Usage

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Preview Changes**:

   ```bash
   terraform plan
   ```

3. **Apply Changes**:

   ```bash
   terraform apply
   ```

4. **Destroy Infrastructure** (optional):

   ```bash
   terraform destroy
   ```

## Main Components

### EC2

Contains the configuration for instances, databases, and load balancers required for the system.

### Lambda

Defines Lambda functions to interact with databases (Neo4j) and storage (S3). Includes the source code and compressed packages for the functions.

### Network

Manages networks, subnets, and security configurations required for the infrastructure.

### Metrics

Configuration for monitoring system performance, including tests, reports, and SSH access.

### S3

Defines configurations for cloud storage, Nginx containers, and configuration files for tools like Prometheus and MongoDB.

### Webservice

Handles the API logic and serves as our main website.

## Contributions

Contributions are welcome. Please open an issue or submit a pull request if you have suggestions or improvements.

## Questions

If you have questions about any aspect of the project, feel free to contact us or open an issue in the repository.



