data "aws_caller_identity" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda_handler.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "s3_trigger_lambda" {
  function_name    = "s3_put_trigger_function"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda-run-role"
  runtime          = "python3.11"
  handler          = "lambda_handler.lambda_handler" # Nombre del archivo y la función a ejecutar
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  depends_on = [ null_resource.create_bucket_and_upload, aws_instance.mage_instance ]

  environment {
    variables = {
      MAGE_API_URL = "http://${aws_eip.mage.public_ip}:6789/api/pipeline_schedules/1/pipeline_runs/test"
    }
  }
}

resource "aws_lambda_permission" "allow_s3_to_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_trigger_lambda.function_name
  principal     = "s3.amazonaws.com"
  depends_on    = [null_resource.create_bucket_and_upload]
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_lambda.arn
    events              = ["s3:ObjectCreated:Put"]

    filter_suffix = ".info"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke]
}
