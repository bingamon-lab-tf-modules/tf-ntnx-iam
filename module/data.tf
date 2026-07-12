##################################################
# Data Sources for IAM
##################################################

# Lookup existing users
data "nutanix_users_v2" "existing_users" {}

# Lookup existing roles
data "nutanix_roles_v2" "existing_roles" {}

# Lookup existing directory services
data "nutanix_directory_services_v2" "existing_directory_services" {}

# Lookup existing SAML identity providers
data "nutanix_saml_identity_providers_v2" "existing_saml_idps" {}

##################################################
# Gated introspection lookups
#
# These read live Prism Central inventory and are only needed when resolving
# IAM operation (permission) ext_ids by name, or auditing existing authorization
# policies. They are gated behind 'var.enable_data_lookups' (default false) so a
# normal plan performs no discovery reads.
##################################################

# Catalog of all IAM operations (permissions), used to resolve operation ext_ids
# referenced by roles/authorization policies.
data "nutanix_operations_v2" "all_operations" {
  count = var.enable_data_lookups ? 1 : 0
}

# Individual IAM operations (permissions) resolved by ext_id.
data "nutanix_operation_v2" "operation" {
  for_each = var.enable_data_lookups ? toset(var.operation_lookup_ext_ids) : toset([])

  ext_id = each.value
}

# Existing authorization policies, for audit / import reference.
data "nutanix_authorization_policies_v2" "existing_authorization_policies" {
  count = var.enable_data_lookups ? 1 : 0
}
