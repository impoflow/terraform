# LocalStack Deployment Test

This file describes the workflow for the `localstack-deployment-test` job.

```mermaid
graph TD
    A[Start: Push to develop or workflow_dispatch]

    %% LocalStack Deployment Test
    A --> B[localstack-deployment-test]
    B --> B1[Checkout repository]
    B --> B2[Install Terraform]
    B --> B3[Install tflocal]
    B --> B4[Start LocalStack]
    B --> B5[Initialize Terraform]
    B --> B6[Generate SSH Key Pair]
    B --> B7[Terraform Plan]

# AWS Deployment Test

This file describes the workflow for the `aws-deployment-test` job.

```mermaid
graph TD
    A[Start: Push to develop or workflow_dispatch]

    %% AWS Deployment Test
    A --> C[aws-deployment-test]
    C --> C1[Checkout Code]
    C --> C2[Configure AWS CLI]
    C --> C3[Install Terraform]
    C --> C4[Terraform Init]
    C --> C5[Generate SSH Key Pair]
    C --> C6[Terraform Plan]
    C --> C7[Terraform Apply]
    C --> C8[Terraform Destroy]

