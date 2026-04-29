output "table_name" {
  value = aws_dynamodb_table.image_index.name
}

output "table_arn" {
  value = aws_dynamodb_table.image_index.arn
}
