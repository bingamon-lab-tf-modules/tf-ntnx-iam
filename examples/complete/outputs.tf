##################################################
# User Outputs
##################################################

output "users" {
  description = "Map of created users with their details"
  value       = module.iam.users
}

output "user_ids" {
  description = "Map of user keys to their external IDs"
  value       = module.iam.user_ids
}

##################################################
# User Group Outputs
##################################################

output "user_groups" {
  description = "Map of created user groups with their details"
  value       = module.iam.user_groups
}

output "user_group_ids" {
  description = "Map of user group keys to their external IDs"
  value       = module.iam.user_group_ids
}

##################################################
# Role Outputs
##################################################

output "roles" {
  description = "Map of created roles with their details"
  value       = module.iam.roles
}

output "role_ids" {
  description = "Map of role keys to their external IDs"
  value       = module.iam.role_ids
}

##################################################
# Directory Service Outputs
##################################################

output "directory_services" {
  description = "Map of configured directory services with their details"
  value       = module.iam.directory_services
}

output "directory_service_ids" {
  description = "Map of directory service keys to their external IDs"
  value       = module.iam.directory_service_ids
}

##################################################
# SAML IDP Outputs
##################################################

output "saml_identity_providers" {
  description = "Map of configured SAML identity providers with their details"
  value       = module.iam.saml_identity_providers
}

output "saml_identity_provider_ids" {
  description = "Map of SAML identity provider keys to their external IDs"
  value       = module.iam.saml_identity_provider_ids
}
