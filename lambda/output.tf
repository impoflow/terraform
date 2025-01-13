output "s3-function-arn" {
  value = aws_lambda_function.s3_trigger_lambda.arn
}

output "neo4j-function-arn" {
  value = aws_lambda_function.neo4j_query_lambda
}