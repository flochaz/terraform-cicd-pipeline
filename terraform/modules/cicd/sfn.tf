
resource "aws_dynamodb_table" "commit_deployment_tracker_table" {
  name           = "CommitDeploymentTracker"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "AccountModuleCommitId"

  attribute {
    name = "AccountModuleCommitId"
    type = "S"
  }

  tags = var.custom_tags

}


resource "aws_sfn_state_machine" "module_plan_apply" {
  name     = "module-plan-apply"
  role_arn = aws_iam_role.sfn_role.arn

  definition = <<EOF
{
  "Comment": "This is your state machine",
  "StartAt": "UpdateAccounts",
  "States": {
    "UpdateAccounts": {
      "Type": "Map",
      "End": true,
      "Iterator": {
        "StartAt": "ModuleAccountCommitDeploymentStatus=DEPLOYING",
        "States": {
          "ModuleAccountCommitDeploymentStatus=DEPLOYING": {
            "Type": "Task",
            "Resource": "arn:aws:states:::dynamodb:putItem",
            "ResultPath": null,
            "Parameters": {
              "TableName": "${aws_dynamodb_table.commit_deployment_tracker_table.name}",
              "Item": {
                "AccountModuleCommitId": {
                  "S.$": "States.Format('{}{}{}', $.AccountId,$.ModuleName,$.CommitId)"
                },
                "UpdatedAt": {
                  "N": "0"
                },
                "STATE": {
                  "S": "DEPLOYING"
                }
              }
            },
            "Next": "terraformPlanApply(account, module, commitId)"
          },
          "terraformPlanApply(account, module, commitId)": {
            "Type": "Task",
            "Resource": "arn:aws:states:::codebuild:startBuild.sync",
            "ResultPath": null,
            "Parameters": {
              "ProjectName.$": "$.ModuleName",
                "SourceVersion.$": "$.CommitId",
                "EnvironmentVariablesOverride": [
                  {
                    "Name": "ACCOUNT_ID",
                    "Value.$": "$.AccountId"
                  },
                  {
                    "Name": "COMMIT_ID",
                    "Value.$": "$.CommitId"
                  },
                  {
                    "Name": "MODULE_NAME",
                    "Value.$": "$.ModuleName"
                  }
                ]
              
            },
            "Catch": [
              {
                "ErrorEquals": [
                  "States.ALL"
                ],
                "Next": "ModuleAccountCommitDeploymentStatus=FAILED"
              }
            ],
            "Next": "ModuleAccountCommitDeploymentStatus=SUCCEEDED"
          },
          "ModuleAccountCommitDeploymentStatus=SUCCEEDED": {
            "Type": "Task",
            "Resource": "arn:aws:states:::dynamodb:putItem",
            "Parameters": {
              "TableName": "${aws_dynamodb_table.commit_deployment_tracker_table.name}",
              "Item": {
                "AccountModuleCommitId": {
                  "S.$": "States.Format('{}{}{}', $.AccountId,$.ModuleName,$.CommitId)"
                },
                "UpdatedAt": {
                  "N": "0"
                },
                "STATE": {
                  "S": "SUCCEEDED"
                }
              }
            },
            "End": true
          },
          "ModuleAccountCommitDeploymentStatus=FAILED": {
            "Type": "Task",
            "Resource": "arn:aws:states:::dynamodb:putItem",
            "Parameters": {
              "TableName": "${aws_dynamodb_table.commit_deployment_tracker_table.name}",
              "Item": {
                "AccountModuleCommitId": {
                  "S.$": "States.Format('{}{}{}', $.AccountId,$.ModuleName,$.CommitId)"
                },
                "UpdatedAt": {
                  "N": "0"
                },
                "STATE": {
                  "S": "FAILED"
                }
              }
            },
            "End": true
          }
        }
      },
      "ItemsPath": "$.accountsmodules"
    }
  }
}
EOF

  tags = var.custom_tags
}