resource "null_resource" "create_bucket_and_upload" {
  provisioner "local-exec" {
    command = <<EOT
      # Verificar si el bucket existe
      if aws s3api head-bucket --bucket ${var.bucket-name} 2>/dev/null; then
        echo "El bucket ${var.bucket-name} ya existe. Eliminando contenido..."
        
        # Eliminar el contenido del bucket
        aws s3 rm s3://${var.bucket-name} --recursive
        
        # Eliminar el bucket
        echo "Eliminando el bucket ${var.bucket-name}..."
        aws s3api delete-bucket --bucket ${var.bucket-name} --region us-east-1
      fi

      # Crear el bucket
      echo "Creando el bucket ${var.bucket-name}..."
      aws s3api create-bucket --bucket ${var.bucket-name} --region us-east-1

      # Subir el archivo neo4j.conf al bucket
      echo "Subiendo neo4j.conf al bucket ${var.bucket-name}..."
      aws s3 cp s3/conf/neo4j.conf s3://${var.bucket-name}/neo4j.conf

      # Subir el archivo mongod.conf al bucket
      echo "Subiendo mongo.conf al bucket ${var.bucket-name}..."
      aws s3 cp s3/conf/mongod.conf s3://${var.bucket-name}/mongod.conf

      # Subir el archivo locustfile.py al bucket
      echo "Subiendo locustfile.py al bucket ${var.bucket-name}..."
      aws s3 cp s3/conf/locustfile.py s3://${var.bucket-name}/locustfile.py

      # Subir el archivo prometheus.yml al bucket
      echo "Subiendo prometheus.yml al bucket ${var.bucket-name}..."
      aws s3 cp s3/conf/prometheus.yml s3://${var.bucket-name}/prometheus.yml

      # Subir el archivo docker-compose.yml al bucket
      echo "Subiendo docker-compose.yml al bucket ${var.bucket-name}..."
      aws s3 cp s3/conf/docker-compose.yml s3://${var.bucket-name}/docker-compose.yml
    EOT
  } 
}