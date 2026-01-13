output "account_id" {
  description = "The AWS account ID"
  value       = aws_organizations_account.account.id
}

output "account_arn" {
  description = "The ARN of the AWS account"
  value       = aws_organizations_account.account.arn
}

output "name" {
  description = "Region Name"
  value       = var.name
}

output "alias" {
  description = "The account name"
  value       = local.name
}

output "email" {
  description = "The account email"
  value       = local.email
}

output "environment" {
  description = "The Account environment"
  value       = var.environment
}

output "role" {
  description = "Account Role"
  value       = var.role
}
