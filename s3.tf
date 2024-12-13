# Bucket genérico para código y ficheros de configuración
resource "aws_s3_bucket" "bucket_for_file" {
  bucket = "neo4j-tscd-23-10-2024"
}

# Subir un archivo a S3
resource "aws_s3_object" "file_upload_neo4j_conf" {
  bucket = aws_s3_bucket.bucket_for_file.bucket
  key    = "neo4j.conf"
  source = "./neo4j.conf"  # Ruta al archivo de configuración de Neo4j
}

resource "aws_s3_object" "zip_upload_neo4j_web_service" {
  bucket = aws_s3_bucket.bucket_for_file.bucket
  key    = "neo4j_web_service.zip"
  source = "../ec2/neo4j_web_service.zip"
}
