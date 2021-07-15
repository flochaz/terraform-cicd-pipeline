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

  # stage {
  #   name = "TerraTest"

  #   action {
  #     name            = "Build-${aws_codebuild_project.codebuild_deployment["test"].name}"
  #     category        = "Build"
  #     owner           = "AWS"
  #     provider        = "CodeBuild"
  #     version         = "1"
  #     run_order       = 1
  #     input_artifacts = ["source_output"]
  #     output_artifacts = ["build_output"]

  #     configuration = {
  #       ProjectName = aws_codebuild_project.codebuild_deployment["test"].name
  #       EnvironmentVariables = jsonencode([{
  #         name  = "ENVIRONMENT"
  #         value = each.value
  #         },
  #         {
  #           name  = "PROJECT_NAME"
  #           value = var.account_type
  #       }])
  #     }
  #   }
  # }

stage {
    name = "DetectChanges"
    action {
      name            = "Build-${aws_codebuild_project.codebuild_deployment["detect"].name}"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 1
      input_artifacts = ["source_output"]
      output_artifacts = ["sfn_input"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_deployment["detect"].name
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
    name = "TerraformMultiAccountDeploy"

    action {
      name            = aws_sfn_state_machine.module_plan_apply.name
      category        = "Invoke"
      owner           = "AWS"
      provider        = "StepFunctions"
      version         = "1"
      run_order       = 1
      input_artifacts = ["sfn_input"]

      configuration = {
        StateMachineArn = aws_sfn_state_machine.module_plan_apply.arn
        InputType = "FilePath"
        Input = "sfn_input.json"
      }
    }
  }

  tags = var.custom_tags
}
