resource "aws_lambda_function" "image_labeler" {
  function_name    = var.function_name
  role             = var.lambda_role_arn
  filename         = var.source_path
  source_code_hash = filebase64sha256(var.source_path)
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = merge({
      DYNAMODB_TABLE       = var.dynamodb_table_name
      CONFIDENCE_THRESHOLD = tostring(var.confidence_threshold)
    }, var.environment_variables)
  }
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  count         = var.allow_s3_invoke ? 1 : 0
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_labeler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.source_bucket_arn
}
