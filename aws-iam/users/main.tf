terraform {
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1" # Altere para a região desejada
}

resource "aws_iam_user" "example_user" {
  name = "example-user"
  path = "/"
}

