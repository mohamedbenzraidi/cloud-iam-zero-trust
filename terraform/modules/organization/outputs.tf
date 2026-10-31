output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "root_id" {
  value = aws_organizations_organization.this.roots[0].id
}

output "management_account_id" {
  value = aws_organizations_organization.this.master_account_id
}

output "account_ids" {
  description = "Map nom court => ID de compte membre."
  value       = { for k, a in aws_organizations_account.member : k => a.id }
}
