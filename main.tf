terraform {
  required_version = ">=1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

module "s3" {
  source          = "./modules/s3"
  bucket_name     = var.bucket_name
  environment     = var.environment
  transition_days = var.transition_days
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  table_name  = var.dynamodb_table_name
  environment = var.environment
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "iam" {
  source             = "./modules/iam"
  name_prefix        = "${var.project_name}-${var.environment}"
  s3_bucket_arn      = module.s3.bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "lambda" {
  source               = "./modules/lambda"
  function_name        = "${var.project_name}-${var.environment}-labeler"
  lambda_role_arn      = module.iam.lambda_role_arn
  source_path          = var.lambda_source_path
  handler              = var.lambda_handler
  runtime              = var.lambda_runtime
  timeout              = var.lambda_timeout
  memory_size          = var.lambda_memory_size
  dynamodb_table_name  = module.dynamodb.table_name
  confidence_threshold = var.confidence_threshold
  source_bucket_arn    = module.s3.bucket_arn
  allow_s3_invoke      = true
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

module "api_lambda" {
  source               = "./modules/lambda"
  function_name        = "${var.project_name}-${var.environment}-api"
  lambda_role_arn      = module.iam.lambda_role_arn
  source_path          = var.api_lambda_source_path
  handler              = "api_handler.lambda_handler"
  runtime              = var.lambda_runtime
  timeout              = var.lambda_timeout
  memory_size          = var.lambda_memory_size
  dynamodb_table_name  = module.dynamodb.table_name
  confidence_threshold = var.confidence_threshold
  environment_variables = {
    BUCKET_NAME = module.s3.bucket_name
  }
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lambda_function_url" "api" {
  function_name      = module.api_lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
    allow_headers = ["*"]
    max_age       = 3600
  }
}

resource "aws_lambda_permission" "api_function_url_public" {
  statement_id            = "AllowPublicFunctionUrlInvoke"
  action                  = "lambda:InvokeFunctionUrl"
  function_name           = module.api_lambda.function_name
  principal               = "*"
  function_url_auth_type  = "NONE"
}

resource "aws_lambda_permission" "api_function_url_public_invoke" {
  statement_id            = "AllowPublicInvokeViaFunctionUrl"
  action                  = "lambda:InvokeFunction"
  function_name           = module.api_lambda.function_name
  principal               = "*"
}

resource "aws_s3_bucket_notification" "image_created_to_lambda" {
  bucket = module.s3.bucket_name

  lambda_function {
    lambda_function_arn = module.lambda.function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "images/"
  }

  depends_on = [module.lambda]
}
