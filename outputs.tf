##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "state_machine_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.this.arn
}

output "state_machine_id" {
  description = "ID of the Step Function state machine"
  value       = aws_sfn_state_machine.this.id
}

output "state_machine_name" {
  description = "Name of the Step Function state machine"
  value       = aws_sfn_state_machine.this.name
}

output "state_machine_status" {
  description = "Current status of the Step Function state machine"
  value       = aws_sfn_state_machine.this.status
}

output "iam_role_arn" {
  description = "ARN of the IAM execution role attached to the state machine"
  value       = aws_iam_role.this.arn
}

output "iam_role_name" {
  description = "Name of the IAM execution role attached to the state machine"
  value       = aws_iam_role.this.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key created for encryption (null if encryption.create is false)"
  value       = var.encryption.create ? aws_kms_key.this[0].arn : null
}

output "kms_key_id" {
  description = "Key ID of the KMS key created for encryption (null if encryption.create is false)"
  value       = var.encryption.create ? aws_kms_key.this[0].key_id : null
}

output "kms_alias_name" {
  description = "Name of the KMS alias created for the encryption key (null if encryption.create is false)"
  value       = var.encryption.create ? aws_kms_alias.this[0].name : null
}

output "activities" {
  description = "Map of activity keys to their ARNs"
  value       = { for k, v in aws_sfn_activity.this : k => v.id }
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group for state machine logging (null if logging is disabled)"
  value       = try(var.settings.logging.enabled, false) ? aws_cloudwatch_log_group.this[0].arn : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group for state machine logging (null if logging is disabled)"
  value       = try(var.settings.logging.enabled, false) ? aws_cloudwatch_log_group.this[0].name : null
}
