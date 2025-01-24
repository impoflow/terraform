data "aws_caller_identity" "current_neo4j" {}

resource "aws_lambda_layer_version" "neo4j_layer" {
  filename   = "lambda/src/layers/neo4j-layer/neo4j-layer.zip"
  layer_name = "neo4j-dependencies-layer"

  compatible_runtimes = ["python3.9", "python3.10", "python3.11", "python3.12", "python3.13"]
  description         = "Layer with Neo4J dependencies"
}

data "archive_file" "lambda_neo4j_query" {
  type        = "zip"
  source_dir  = "lambda/src/neo"
  output_path = "lambda/src/neo/neo_lambda_function.zip"
}

resource "aws_lambda_function" "neo4j_query_lambda" {
  function_name    = "neo4j_query_handler_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda-run-role"
  runtime          = "python3.11"
  handler          = "neo_lambda_handler.lambda_handler" # Nombre del archivo y la función a ejecutar
  filename         = data.archive_file.lambda_neo4j_query.output_path
  source_code_hash = data.archive_file.lambda_neo4j_query.output_base64sha256
  timeout          = 7

  environment {
    variables = {
      LOG_LEVEL      = "INFO",
      NEO4J_URI      = "bolt://${var.neo4j-ip}:7687"
      NEO4J_USER     = "neo4j"
      NEO4J_PASSWORD = "${var.neo4j-passwd}"
    }
  }

  layers = [aws_lambda_layer_version.neo4j_layer.arn]
}