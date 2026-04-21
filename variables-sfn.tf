##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Activities for the Step Function yaml Format
# activities:
#   name_prefix: "my-activity" # (optional) name must be set if name_prefix is not set
#   name: "my-activity-name"   # (optional) overrides name_prefix
#   encryption:
#     enabled: true | false    # (optional) default is false overriden by encryption.create in the module
#     reuse_period_seconds: 60 # (optional) default is null
#     aws_kms: true | false # (optional) default is false
#     kms_key_arn: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" # (optional) default is null or the one created by the module
variable "activities" {
  description = "Map of activities to create in the Step Function"
  type        = any
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for the Step Function name"
  type        = string
}

variable "encryption" {
  description = "Enable encryption for the Step Function activities"
  type = object({
    create              = optional(bool, false)
    enabled             = optional(bool, true)
    deletion_window     = optional(number, 30)
    enable_key_rotation = optional(bool, true)
    rotation_period     = optional(number, 90)
  })
  default = {}
}

# Step Function settings - Yaml format
# settings:
#   is_express: true | false # (optional) default is false
#   publish: true | false # (optional) default is null
#   definition: "" | {} # (Required) JSON String or YAML definition of the Step Function
#   kms_reuse_period_seconds: 60 # (optional) default is null - only applies when encryption.create is true
#   logging:
#     enabled: true | false # (optional) default is false
#     level: "ALL" | "ERROR" | "FATAL" | "OFF" # (optional) default is "ERROR"
#     include_execution_data: true | false # (optional) default is false
#     retention_in_days: 90 # (optional) CloudWatch log group retention in days, default is 90
#   tracing:
#     enabled: true | false # (optional) Enable AWS X-Ray tracing for state machine executions. default is false
#   iam:
#     policy_statements: # (optional) list of IAM policy statements to attach to the Step Function role
#       - sid: "StatementID" # (optional) unique identifier for the statement
#         effect: "Allow" | "Deny" # (optional) default is "Allow"
#         actions: ["sfn:StartExecution", "sfn:StopExecution"] # (optional) list of actions to allow
#         resources: ["arn:aws:sfn:us-east-1:123456789012:stateMachine:MyStateMachine"] # (optional) list of resources to apply the policy to
#         conditions: # (optional) list of conditions for the policy statement
#           - test: "StringEquals" # (optional) condition test
#             variable: "aws:SourceArn" # (optional) condition variable
#             values: ["arn:aws:sfn:us-east-1:123456789012:stateMachine:MyStateMachine"] # (optional) list of values for the condition
variable "settings" {
  description = "Settings for the Step Function"
  type        = any
  default     = {}
}