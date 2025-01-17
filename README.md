## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws-ec2"></a> [aws-ec2](#module\_aws-ec2) | ./ec2 | n/a |
| <a name="module_aws-lambda"></a> [aws-lambda](#module\_aws-lambda) | ./lambda | n/a |
| <a name="module_aws-metrics"></a> [aws-metrics](#module\_aws-metrics) | ./metrics | n/a |
| <a name="module_aws-network"></a> [aws-network](#module\_aws-network) | ./network | n/a |
| <a name="module_aws-s3"></a> [aws-s3](#module\_aws-s3) | ./s3 | n/a |
| <a name="module_aws-webservice"></a> [aws-webservice](#module\_aws-webservice) | ./webservice | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket-name"></a> [bucket-name](#input\_bucket-name) | bucket name | `string` | `"neo4j-tscd-310-10-2024"` | no |
| <a name="input_docker-passwd"></a> [docker-passwd](#input\_docker-passwd) | Password for DockerHub | `string` | n/a | yes |
| <a name="input_docker-username"></a> [docker-username](#input\_docker-username) | Username for DockerHub | `string` | `"autogram"` | no |
| <a name="input_github-mage-token"></a> [github-mage-token](#input\_github-mage-token) | Token for GitHub | `string` | `"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"` | no |
| <a name="input_github-webservice-token"></a> [github-webservice-token](#input\_github-webservice-token) | Token for GitHub | `string` | `"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"` | no |
| <a name="input_mongodb-passwd"></a> [mongodb-passwd](#input\_mongodb-passwd) | Password for mongodb | `string` | n/a | yes |
| <a name="input_mongodb-username"></a> [mongodb-username](#input\_mongodb-username) | Nombre de usuario para MongoDB | `string` | `"user"` | no |
| <a name="input_neo4j-passwd"></a> [neo4j-passwd](#input\_neo4j-passwd) | Password for neo4j | `string` | n/a | yes |
| <a name="input_neo4j-username"></a> [neo4j-username](#input\_neo4j-username) | Nombre de usuario para MongoDB | `string` | `"neo4j"` | no |
| <a name="input_region"></a> [region](#input\_region) | value of the region | `string` | `"us-east-1"` | no |
| <a name="input_ssh-key-name"></a> [ssh-key-name](#input\_ssh-key-name) | Nombre de la clave SSH para acceder a la instancia | `string` | `"~/.ssh/my-ssh-key.pub"` | no |

## Outputs

No outputs.
