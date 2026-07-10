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

# Lookup available operations (for role creation)
data "nutanix_operations_v2" "all_operations" {}
