data "aws_caller_identity" "current" {}

data "archive_file" "lambda_neo4j_query" {
  type        = "zip"
  source_file = "lambda/neo_lambda_handler.py"
  output_path = "lambda/neo_lambda_function.zip"
}

resource "aws_lambda_function" "neo4j_query_lambda" {
  function_name    = "neo4j_query_handler_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda-run-role"
  runtime          = "python3.11"
  handler          = "neo_lambda_handler.lambda_handler" # Nombre del archivo y la función a ejecutar
  filename         = data.archive_file.lambda_neo4j_query.output_path
  source_code_hash = data.archive_file.lambda_neo4j_query.output_base64sha256

  depends_on = [ null_resource.neo4j_instance ]

  environment {
    variables = {
      LOG_LEVEL = "INFO",
      NEO4J_URI = "bolt://${aws_eip.neo4j.public_ip}:7687"
      NEO4J_USER = "neo4j"
      NEO4J_PASSWORD = "${var.neo4j-passwd}"
    }
  }
}