##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_iam_policy_document" "kms_policy" {
  count = var.encryption.create ? 1 : 0
   statement {
    sid    = "AllowRootUserFullAccess"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
      type = "AWS"
    }
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "AllowUseOfTheKeyCreator"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      identifiers = [
        data.aws_iam_session_context.current.issuer_arn
      ]
      type = "AWS"
    }
    resources = [
      "*"
    ]
  }
}

resource "aws_kms_key" "this" {
  count                   = var.encryption.create ? 1 : 0
  description             = "KMS Key for Step Function Activities"
  deletion_window_in_days = var.encryption.deletion_window
  enable_key_rotation     = var.encryption.enable_key_rotation
  rotation_period_in_days = var.encryption.rotation_period
  is_enabled              = var.encryption.enabled
  policy                  = data.aws_iam_policy_document.kms_policy[0].json
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count         = var.encryption.create ? 1 : 0
  target_key_id = aws_kms_key.this[0].arn
  name          = format("alias/sfn/%s-%s", var.name_prefix, local.system_name_short)
}
