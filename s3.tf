resource "null_resource" "create_bucket_and_upload" {
  provisioner "local-exec" {
    command = <<EOT
      # Check if the bucket exists; create it if it doesn't
      if ! aws s3api head-bucket --bucket neo4j-tscd-100-10-2024 2>/dev/null; then
        aws s3api create-bucket --bucket neo4j-tscd-100-10-2024 --region us-east-1
      fi

      # Upload the neo4j.conf file to the bucket
      aws s3 cp ./neo4j.conf s3://neo4j-tscd-100-10-2024/neo4j.conf
    EOT
  }
}