output "instance_arn" { value = local.instance_arn }
output "identity_store_id" { value = local.identity_store_id }
output "group_ids" { value = { for k, g in aws_identitystore_group.this : k => g.group_id } }
output "permission_set_arns" { value = { for k, p in aws_ssoadmin_permission_set.this : k => p.arn } }
