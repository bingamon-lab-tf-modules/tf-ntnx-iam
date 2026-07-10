locals {

  ##################################################
  # Users
  ##################################################

  # Users that are active
  active_users = { for k, v in var.users : k => v if v.status == "ACTIVE" }

  # Users that are service accounts
  service_account_users = { for k, v in var.users : k => v if v.user_type == "SERVICE_ACCOUNT" }

  # Users that are SAML users
  saml_users = { for k, v in var.users : k => v if v.user_type == "SAML" }

  # Users that are LDAP users
  ldap_users = { for k, v in var.users : k => v if v.user_type == "LDAP" }

  # Users that are local users
  local_users = { for k, v in var.users : k => v if v.user_type == "LOCAL" }

  ##################################################
  # User Groups
  ##################################################

  # LDAP user groups
  ldap_user_groups = { for k, v in var.user_groups : k => v if v.group_type == "LDAP" }

  # SAML user groups
  saml_user_groups = { for k, v in var.user_groups : k => v if v.group_type == "SAML" }

  ##################################################
  # Directory Services
  ##################################################

  # Active Directory services
  active_directory_services = { for k, v in var.directory_services : k => v if v.directory_type == "ACTIVE_DIRECTORY" }

  # OpenLDAP directory services
  open_ldap_services = { for k, v in var.directory_services : k => v if v.directory_type == "OPEN_LDAP" }
}
