##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
locals {
  sfn_name = format("%s-%s-role", var.name_prefix, local.system_name_short)
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "states.amazonaws.com"
      ]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:states:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.sfn_name}*"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

data "aws_iam_policy_document" "sfn_policy" {
  count = length(try(var.settings.iam.policy_statements, [])) > 0 ? 1 : 0
  dynamic "statement" {
    for_each = var.settings.iam.policy_statements
    content {
      sid       = try(statement.value.sid, null)
      effect    = try(statement.value.effect, "Allow")
      actions   = try(statement.value.actions, [])
      resources = try(statement.value.resources, [])
      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = try(condition.value.test, null)
          variable = try(condition.value.variable, null)
          values   = try(condition.value.values, [])
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.sfn_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.all_tags
}

resource "aws_iam_role_policy" "this" {
  count  = length(try(var.settings.iam.policy_statements, [])) > 0 ? 1 : 0
  name   = "StepFunctionInlinePolicy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.sfn_policy[0].json
}