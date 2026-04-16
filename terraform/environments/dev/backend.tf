terraform {
    backend "s3" {
        bucket = "weather-platform-tfstate" # Create this bucket first
        key = "dev/terraform.tfstate"
        region = "us-east-1"
        encrypt = true
    }
}