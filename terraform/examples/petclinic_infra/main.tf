provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


module "petclinic_infra" {
  source = "../../modules/petclinic_infra"
  aws_region="eu-west-1"
  stack="terraform-workshop"
  fargate-task-service-role="terraform-workshop-role"
  aws_ecr="petclinic"
  aws_profile="default"
  source_repo_name="petclinic"
  source_repo_branch="master"
  image_repo_name="petclinic"
}
