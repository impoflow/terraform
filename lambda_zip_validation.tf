data "aws_caller_identity" "current" {}

data "archive_file" "lambda_zip_validator" {
  type        = "zip"
  source_file = "lambda/zip_validator_handler.py"
  output_path = "lambda/zip_validator_function.zip"
}

resource "aws_lambda_function" "zip_validator_lambda" {
  function_name    = "zip_validator_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda-run-role"
  runtime          = "python3.11"
  handler          = "zip_validator_handler.lambda_handler" # Nombre del archivo y la función a ejecutar
  filename         = data.archive_file.lambda_zip_validator.output_path
  source_code_hash = data.archive_file.lambda_zip_validator.output_base64sha256

  depends_on = [ null_resource.ec2_instance_with_zip ]

  environment {
    variables = {
      LOG_LEVEL = "INFO",
    }
  }
}

resource "aws_lambda_permission" "allow_ec2_to_invoke" {
  statement_id  = "AllowEC2Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.zip_validator_lambda.function_name
  principal     = "ec2.amazonaws.com"
  depends_on    = [null_resource.ec2_instance_with_zip]
}