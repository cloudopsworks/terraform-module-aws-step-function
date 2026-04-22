##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

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

data "aws_iam_policy_document" "lambda_invoke_policy" {
  count = length(try(var.settings.lambdas, [])) > 0 ? 1 : 0
  statement {
    sid    = "LambdaInvokePermission"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      for key, lambda_name in try(var.settings.lambdas, {}) : data.aws_lambda_function.lambda[key].arn
    ]
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
  name               = format("%s-role", local.sfn_name)
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.all_tags
}

resource "aws_iam_role_policy" "this" {
  count  = length(try(var.settings.iam.policy_statements, [])) > 0 ? 1 : 0
  name   = "StepFunctionInlinePolicy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.sfn_policy[0].json
}

resource "aws_iam_role_policy" "lambda_invoke" {
  count = length(try(var.settings.lambdas, [])) > 0 ? 1 : 0
  name   = "StepFunctionLambdaInvokePolicy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_invoke_policy[0].json
}

data "aws_iam_policy_document" "sfn_cloudwatch_policy" {
  count = try(var.settings.logging.enabled, false) ? 1 : 0

  # Log delivery control-plane actions require * resource per AWS documentation
  statement {
    sid    = "CloudWatchLogDelivery"
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }

  # Log write actions scoped to the module-managed log group
  statement {
    sid    = "CloudWatchLogWrite"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.this[0].arn,
      "${aws_cloudwatch_log_group.this[0].arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  count  = try(var.settings.logging.enabled, false) ? 1 : 0
  name   = "StepFunctionCloudWatchPolicy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.sfn_cloudwatch_policy[0].json
}