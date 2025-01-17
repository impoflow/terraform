data "aws_caller_identity" "current_neo4j" {}

data "archive_file" "lambda_neo4j_query" {
  type        = "zip"
  source_dir  = "lambda/src/neo"
  output_path = "lambda/src/neo/neo_lambda_function.zip"
}

resource "aws_lambda_function" "neo4j_query_lambda" {
  function_name    = "neo4j_query_handler_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  runtime          = "python3.11"
  handler          = "neo_lambda_handler.lambda_handler" # Nombre del archivo y la función a ejecutar
  filename         = data.archive_file.lambda_neo4j_query.output_path
  source_code_hash = data.archive_file.lambda_neo4j_query.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL      = "INFO",
      NEO4J_URI      = "bolt://${var.neo4j-ip}:7687"
      NEO4J_USER     = "neo4j"
      NEO4J_PASSWORD = "${var.neo4j-passwd}"
    }
  }
}