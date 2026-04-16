variable "name" {
  type = string
}

variable "secret_values" {
  type      = map(string)
  sensitive = true
}