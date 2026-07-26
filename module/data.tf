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

# Existing API keys issued to specific users, for audit / rotation reference.
# The data source requires a user ext_id per query, so this fans out over
# 'var.user_key_lookup_user_ext_ids'.
data "nutanix_user_keys_v2" "user_keys" {
  for_each = var.enable_data_lookups ? toset(var.user_key_lookup_user_ext_ids) : toset([])

  user_ext_id = each.value
}

##################################################
# Role lookup by display name
#
# Built-in role ext_ids are per-Prism-Central UUIDs, so an authorization policy
# cannot portably hard-code one. This resolves a role by its display name at
# plan time instead.
#
# Deliberately one exact-match query per name rather than reading
# 'existing_roles' above and filtering in HCL: that data source takes the API's
# default page size of 50, and a stock Prism Central already ships 60 roles, so
# a name-to-ext_id map built from it would silently miss whatever fell off the
# first page. An '$filter=displayName eq ...' query is exact regardless of how
# many roles exist.
#
# NOT gated behind var.enable_data_lookups: this is required to resolve a
# policy the caller has explicitly asked for, not optional discovery, and it
# only runs when some policy actually sets 'role_name'.
##################################################

data "nutanix_roles_v2" "role_by_name" {
  for_each = local.authz_role_names

  filter = "displayName eq '${each.value}'"
}
