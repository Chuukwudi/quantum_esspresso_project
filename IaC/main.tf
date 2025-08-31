terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-1"
}

# IAM
variable "existing_role_arn" {
  type        = string
  default     = "arn:aws:iam::891377350630:role/lambda-stuff"
  description = "ARN of the existing IAM role to use"
}

# Lambda
variable "entry_lambda_function_name" {
  type        = string
  default     = "<lambda_function_name>"
  description = "Name of the Lambda function to be created"
}