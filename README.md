# terraform-setup

To execute the terraform apply, make sure you make use of the following command, specifying both DockerHub username and password.

```bash
terraform apply -var="docker-username=DOCKER_USERNAME" -var="docker-passwd=$DOCKER_PASSWD"
```

# CI/CD Workflows

- [LocalStack Deployment Test](localstack-deployment-test.md)
- [AWS Deployment Test](aws-deployment-test.md)