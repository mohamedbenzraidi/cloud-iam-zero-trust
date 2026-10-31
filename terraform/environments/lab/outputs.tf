output "organization_id" { value = module.organization.organization_id }
output "account_ids" { value = local.all_account_ids }
output "cloudtrail_bucket" { value = module.org_cloudtrail.bucket_name }
output "identity_center_instance_arn" { value = module.identity_center.instance_arn }
output "identity_store_id" { value = module.identity_center.identity_store_id }
