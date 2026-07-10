locals {

  ##################################################
  # Users
  ##################################################

  # Users with their (sensitive) password merged back in from the dedicated
  # 'var.user_passwords' map. Consumed by the nutanix_users_v2 resource.
  users = {
    for k, u in var.users : k => merge(u, {
      password = lookup(var.user_passwords, k, null)
    })
  }

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

  # Directory services with the (sensitive) service account password merged
  # back in from the dedicated 'var.directory_service_passwords' map. Consumed
  # by the nutanix_directory_services_v2 resource.
  directory_services = {
    for k, v in var.directory_services : k => merge(v, {
      service_account = merge(v.service_account, {
        password = lookup(var.directory_service_passwords, k, null)
      })
    })
  }

  # Active Directory services
  active_directory_services = { for k, v in var.directory_services : k => v if v.directory_type == "ACTIVE_DIRECTORY" }

  # OpenLDAP directory services
  open_ldap_services = { for k, v in var.directory_services : k => v if v.directory_type == "OPEN_LDAP" }
}
