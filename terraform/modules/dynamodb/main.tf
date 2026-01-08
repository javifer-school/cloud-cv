# =============================================================================
# DynamoDB Module - Visit Counter Table
# =============================================================================

resource "aws_dynamodb_table" "visit_counter" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "visitor_ip"

  attribute {
    name = "visitor_ip"
    type = "S"
  }

  # Point-in-time recovery for backups
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # TTL for automatic cleanup (optional - disabled by default)
  ttl {
    attribute_name = "ttl"
    enabled        = false
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# Global Secondary Index for querying by date (optional future enhancement)
# -----------------------------------------------------------------------------
# Uncomment if needed for date-based queries
# resource "aws_dynamodb_table" "visit_counter_with_gsi" {
#   ...
#   global_secondary_index {
#     name            = "last_visit_index"
#     hash_key        = "visit_date"
#     projection_type = "ALL"
#   }
# }
