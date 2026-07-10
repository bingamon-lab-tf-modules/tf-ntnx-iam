##################################################
# User Outputs
##################################################

output "users" {
  description = "Map of created users with their details."
  value = {
    for k, v in nutanix_users_v2.user : k => {
      ext_id       = v.ext_id
      username     = v.username
      user_type    = v.user_type
      display_name = v.display_name
      email_id     = v.email_id
      status       = v.status
    }
  }
}

output "user_ids" {
  description = "Map of user keys to their external IDs."
  value       = { for k, v in nutanix_users_v2.user : k => v.ext_id }
}

##################################################
# User Group Outputs
##################################################

output "user_groups" {
  description = "Map of created user groups with their details."
  value = {
    for k, v in nutanix_user_groups_v2.group : k => {
      ext_id             = v.ext_id
      group_type         = v.group_type
      idp_id             = v.idp_id
      name               = v.name
      distinguished_name = v.distinguished_name
    }
  }
}

output "user_group_ids" {
  description = "Map of user group keys to their external IDs."
  value       = { for k, v in nutanix_user_groups_v2.group : k => v.ext_id }
}

##################################################
# Role Outputs
##################################################

output "roles" {
  description = "Map of created roles with their details."
  value = {
    for k, v in nutanix_roles_v2.role : k => {
      ext_id       = v.ext_id
      display_name = v.display_name
      description  = v.description
      operations   = v.operations
    }
  }
}

output "role_ids" {
  description = "Map of role keys to their external IDs."
  value       = { for k, v in nutanix_roles_v2.role : k => v.ext_id }
}

##################################################
# Directory Service Outputs
##################################################

output "directory_services" {
  description = "Map of created directory services with their details."
  value = {
    for k, v in nutanix_directory_services_v2.directory_service : k => {
      ext_id         = v.ext_id
      name           = v.name
      url            = v.url
      domain_name    = v.domain_name
      directory_type = v.directory_type
    }
  }
}

output "directory_service_ids" {
  description = "Map of directory service keys to their external IDs."
  value       = { for k, v in nutanix_directory_services_v2.directory_service : k => v.ext_id }
}

##################################################
# SAML Identity Provider Outputs
##################################################

output "saml_identity_providers" {
  description = "Map of created SAML identity providers with their details."
  value = {
    for k, v in nutanix_saml_identity_providers_v2.saml_idp : k => {
      ext_id        = v.ext_id
      name          = v.name
      username_attr = v.username_attr
      email_attr    = v.email_attr
      groups_attr   = v.groups_attr
    }
  }
}

output "saml_identity_provider_ids" {
  description = "Map of SAML IDP keys to their external IDs."
  value       = { for k, v in nutanix_saml_identity_providers_v2.saml_idp : k => v.ext_id }
}

##################################################
# Summary
##################################################

output "iam_summary" {
  description = "Summary of IAM resources managed by this module."
  value = {
    total_users              = length(var.users)
    total_user_groups        = length(var.user_groups)
    total_roles              = length(var.roles)
    total_directory_services = length(var.directory_services)
    total_saml_idps          = length(var.saml_identity_providers)
  }
}
