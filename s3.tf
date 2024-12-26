resource "null_resource" "create_bucket_and_upload" {
  provisioner "local-exec" {
    command = <<EOT
      # Verificar si el bucket existe
      if aws s3api head-bucket --bucket ${var.bucket_name} 2>/dev/null; then
        echo "El bucket ${var.bucket_name} ya existe. Eliminando contenido..."
        
        # Eliminar el contenido del bucket
        aws s3 rm s3://${var.bucket_name} --recursive
        
        # Eliminar el bucket
        echo "Eliminando el bucket ${var.bucket_name}..."
        aws s3api delete-bucket --bucket ${var.bucket_name} --region us-east-1
      fi

      # Crear el bucket
      echo "Creando el bucket ${var.bucket_name}..."
      aws s3api create-bucket --bucket ${var.bucket_name} --region us-east-1

      # Subir el archivo neo4j.conf al bucket
      echo "Subiendo neo4j.conf al bucket ${var.bucket_name}..."
      aws s3 cp ./neo4j.conf s3://${var.bucket_name}/neo4j.conf
    EOT
  }
}