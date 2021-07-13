resource "aws_iam_role" "sfn_role" {
  name = "${var.git_repository_name}_sfn_module_deploy_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "${var.git_repository_name}_sfn_deployment_policy"
  role = aws_iam_role.sfn_role.name

  policy = templatefile("${path.module}/templates/sfn-role-policy.json.tpl",
    {
      dynamodb_table = aws_dynamodb_table.commit_deployment_tracker_table.arn,
      codebuild = aws_codebuild_project.hello_world_codebuild_project.arn
  })
}
