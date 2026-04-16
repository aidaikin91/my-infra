resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Always declare the hash key attribute
  attribute {
    name = var.hash_key
    type = "S"
  }

  # Only declare range key attribute if range_key is provided
  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
      type = "S"
    }
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
  }
}
