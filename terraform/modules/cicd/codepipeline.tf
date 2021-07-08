resource "aws_codecommit_repository" "code_repo" {
  repository_name = var.git_repository_name
  description     = "Code Repository"

  tags = var.custom_tags
}

resource "aws_codepipeline" "codepipeline" {
  for_each = toset(var.branches)
  name     = "${var.git_repository_name}-${each.value}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source-${var.git_repository_name}"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = var.git_repository_name
        BranchName     = each.value
      }
    }
  }

  stage {
    name = "Test"

    action {
      name            = "Build-${aws_codebuild_project.codebuild_deployment["test"].name}"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_deployment["test"].name
        EnvironmentVariables = jsonencode([{
          name  = "ENVIRONMENT"
          value = each.value
          },
          {
            name  = "PROJECT_NAME"
            value = var.account_type
        }])
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name            = "Build-${aws_codebuild_project.codebuild_deployment["plan"].name}"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["source_output"]
      output_artifacts = ["plan_output"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_deployment["plan"].name
        EnvironmentVariables = jsonencode([{
          name  = "ENVIRONMENT"
          value = each.value
          },
          {
            name  = "PROJECT_NAME"
            value = var.account_type
        }])
      }
    }
    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Apply"
    action {
      name            = "Build-${aws_codebuild_project.codebuild_deployment["apply"].name}"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["plan_output"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_deployment["apply"].name
        EnvironmentVariables = jsonencode([{
          name  = "ENVIRONMENT"
          value = each.value
          },
          {
            name  = "PROJECT_NAME"
            value = var.account_type
        }])
      }
    }
  }
  tags = var.custom_tags
}
