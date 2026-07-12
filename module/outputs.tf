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
      username_attr = v.username_attribute
      email_attr    = v.email_attribute
      groups_attr   = v.groups_attribute
    }
  }
}

output "saml_identity_provider_ids" {
  description = "Map of SAML IDP keys to their external IDs."
  value       = { for k, v in nutanix_saml_identity_providers_v2.saml_idp : k => v.ext_id }
}

##################################################
# Authorization Policy Outputs
##################################################

output "authorization_policies" {
  description = "Map of created authorization policies (role bindings) with their details."
  value = {
    for k, v in nutanix_authorization_policy_v2.authorization_policy : k => {
      ext_id                    = v.ext_id
      display_name              = v.display_name
      role                      = v.role
      description               = v.description
      authorization_policy_type = v.authorization_policy_type
      is_system_defined         = v.is_system_defined
    }
  }
}

output "authorization_policy_ids" {
  description = "Map of authorization policy keys to their external IDs."
  value       = { for k, v in nutanix_authorization_policy_v2.authorization_policy : k => v.ext_id }
}

##################################################
# User API Key Outputs
##################################################

# SENSITIVE: 'key_details' carries the generated key material (api_key for
# API_KEY, access_key/secret_key for OBJECT_KEY). Marked sensitive so the
# material is never rendered in plan/apply output or logs; it lives only in
# (encrypted) state. Consume it downstream through a sensitive channel.
output "user_keys" {
  description = "Map of issued user API keys with their details, including generated key material. SENSITIVE."
  sensitive   = true
  value = {
    for k, v in nutanix_user_key_v2.user_key : k => {
      ext_id      = v.ext_id
      name        = v.name
      key_type    = v.key_type
      user_ext_id = v.user_ext_id
      status      = v.status
      expiry_time = v.expiry_time
      key_details = v.key_details
    }
  }
}

output "user_key_ids" {
  description = "Map of user key map keys to their external IDs (key identifiers, not secret material)."
  value       = { for k, v in nutanix_user_key_v2.user_key : k => v.ext_id }
}

##################################################
# Summary
##################################################

output "iam_summary" {
  description = "Summary of IAM resources managed by this module."
  value = {
    total_users                  = length(var.users)
    total_user_groups            = length(var.user_groups)
    total_roles                  = length(var.roles)
    total_directory_services     = length(var.directory_services)
    total_saml_idps              = length(var.saml_identity_providers)
    total_authorization_policies = length(var.authorization_policies)
    total_user_keys              = length(var.user_keys)
    total_user_key_revocations   = length(var.user_key_revocations)
  }
}
