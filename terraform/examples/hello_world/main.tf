provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


module "hello_world" {
  source = "../../modules/hello_world"
}
