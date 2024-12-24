resource "null_resource" "create_bucket_and_upload" {
  provisioner "local-exec" {
    command = <<EOT
      # Check if the bucket exists; create it if it doesn't
      if ! aws s3api head-bucket --bucket ${var.bucket_name} 2>/dev/null; then
        aws s3api create-bucket --bucket ${var.bucket_name} --region us-east-1
      fi

      # Upload the neo4j.conf file to the bucket
      aws s3 cp ./neo4j.conf s3://${var.bucket_name}/neo4j.conf
    EOT
  }
}