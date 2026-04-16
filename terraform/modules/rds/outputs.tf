output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "username" {
  value = aws_db_instance.this.username
}

output "password" {
  value     = random_password.db_password.result
  sensitive = true
}

output "db_name" {
  value = aws_db_instance.this.db_name
}