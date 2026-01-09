# DynamoDB table for visit counter
resource "aws_dynamodb_table" "visit_counter" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "visitor_ip"

  attribute {
    name = "visitor_ip"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }

  tags = {
    Name        = var.table_name
    Environment = var.environment
    Project     = var.project_name
  }
}
