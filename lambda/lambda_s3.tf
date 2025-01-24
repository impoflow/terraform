data "aws_caller_identity" "current" {}

data "archive_file" "lambda_s3" {
  type        = "zip"
  source_file = "lambda/src/s3/s3_lambda_handler.py"
  output_path = "lambda/src/s3/s3_lambda_function.zip"
}

resource "aws_lambda_function" "s3_trigger_lambda" {
  function_name    = "s3_put_trigger_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda-run-role"
  runtime          = "python3.11"
  handler          = "s3_lambda_handler.lambda_handler" # Nombre del archivo y la función a ejecutar
  filename         = data.archive_file.lambda_s3.output_path
  source_code_hash = data.archive_file.lambda_s3.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL    = "INFO",
      MAGE_API_URL = "http://${var.mage-ip}:6789/api/pipeline_schedules/1/pipeline_runs/s3PutTrigger"
    }
  }
}

resource "aws_lambda_permission" "allow_s3_to_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_trigger_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket-name}"
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = var.bucket-name

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_lambda.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke]
}
