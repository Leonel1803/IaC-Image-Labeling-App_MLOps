output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "lambda_role_name" {
  value = module.iam.lambda_role_name
}

output "api_lambda_function_name" {
  value = module.api_lambda.function_name
}

output "api_function_url" {
  value = aws_lambda_function_url.api.function_url
}
