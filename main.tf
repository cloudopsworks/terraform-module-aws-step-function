##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  sfn_name = format("%s-%s", var.name_prefix, local.system_name_short)
}

resource "aws_kms_key" "this" {
  count                   = var.encryption.create ? 1 : 0
  description             = "KMS Key for Step Function Activities"
  deletion_window_in_days = var.encryption.deletion_window
  enable_key_rotation     = var.encryption.enable_key_rotation
  rotation_period_in_days = var.encryption.rotation_period
  is_enabled              = var.encryption.enabled
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count         = var.encryption.create ? 1 : 0
  target_key_id = aws_kms_key.this[0].arn
  name          = format("alias/sfn/%s-%s", var.name_prefix, local.system_name_short)
}

resource "aws_sfn_activity" "this" {
  for_each = var.activities
  name     = try(each.value.name, format("%s-%s", each.value.name_prefix, local.system_name_short))
  dynamic "encryption_configuration" {
    for_each = try(each.value.encryption.enabled, false) || var.encryption.create ? [1] : []
    content {
      kms_key_id                        = try(each.value.encryption.aws_kms, false) ? null : try(each.value.encryption.kms_key_arn, aws_kms_key.this[0].arn, null)
      type                              = try(each.value.encryption.aws_kms, false) ? "AWS_KMS_KEY" : (try(each.value.encryption.kms_key_arn, aws_kms_key.this[0].arn, "") != "" ? "CUSTOMER_MANAGED_KMS_KEY" : "AWS_KMS_KEY")
      kms_data_key_reuse_period_seconds = try(each.value.encryption.reuse_period_seconds, var.settings.kms_reuse_period_seconds, null)
    }
  }
  tags = merge(
    local.all_tags,
    try(each.value.tags, {})
  )
}

resource "aws_sfn_state_machine" "this" {
  name       = local.sfn_name
  type       = try(var.settings.is_express, false) ? "EXPRESS" : "STANDARD"
  role_arn   = aws_iam_role.this.arn
  publish    = try(var.settings.publish, null)
  definition = try(yamlencode(var.settings.definition), var.settings.definition)
  dynamic "encryption_configuration" {
    for_each = var.encryption.create ? [1] : []
    content {
      kms_key_id                        = aws_kms_key.this[0].arn
      type                              = "CUSTOMER_MANAGED_KMS_KEY"
      kms_data_key_reuse_period_seconds = try(var.settings.kms_reuse_period_seconds, null)
    }
  }
  dynamic "logging_configuration" {
    for_each = try(var.settings.logging.enabled, false) ? [1] : []
    content {
      level                  = try(var.settings.logging.level, "ERROR")
      include_execution_data = try(var.settings.logging.include_execution_data, false)
      log_destination        = "${aws_cloudwatch_log_group.this[0].arn}:*"
    }
  }
  dynamic "tracing_configuration" {
    for_each = try(var.settings.tracing.enabled, false) ? [1] : []
    content {
      enabled = true
    }
  }
  tags = local.all_tags

  lifecycle {
    precondition {
      condition     = try(var.settings.definition, null) != null
      error_message = "settings.definition must be provided — an empty state machine definition is not valid."
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  count             = try(var.settings.logging.enabled, false) ? 1 : 0
  name              = format("/aws/sfn/%s", local.sfn_name)
  retention_in_days = try(var.settings.logging.retention_in_days, 90)
  tags              = local.all_tags
}