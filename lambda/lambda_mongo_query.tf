data "aws_caller_identity" "current_mongodb" {}

resource "aws_lambda_layer_version" "mongo_layer" {
  filename   = "lambda/src/layers/pymongo-layer/pymongo-layer.zip"
  layer_name = "mongo-dependencies-layer"

  compatible_runtimes = ["python3.9", "python3.10", "python3.11", "python3.12", "python3.13"]
  description         = "Layer with MongoDB dependencies"
}


data "archive_file" "lambda_mongo_query" {
  type        = "zip"
  source_dir  = "lambda/src/mongo"
  output_path = "lambda/src/mongo/mongo_lambda_function.zip"
}

resource "aws_lambda_function" "mongo_query_lambda" {
  function_name    = "mongo_query_handler_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda-run-role"
  runtime          = "python3.11"
  handler          = "mongo_lambda_handler.lambda_handler"
  filename         = data.archive_file.lambda_mongo_query.output_path
  source_code_hash = data.archive_file.lambda_mongo_query.output_base64sha256
  timeout          = 7

  environment {
    variables = {
      LOG_LEVEL      = "INFO",
      MONGO_URI      = "mongodb://${var.mongodb-username}:${var.mongodb-passwd}@${var.mongodb-ip}:27017"
    }
  }

  layers = [aws_lambda_layer_version.mongo_layer.arn]
}