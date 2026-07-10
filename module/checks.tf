# Validate that LDAP user groups have a distinguished name.
check "ldap_groups_have_dn" {
  assert {
    condition = alltrue([
      for k, v in var.user_groups :
      v.group_type != "LDAP" || v.distinguished_name != null
    ])
    error_message = "LDAP user groups should have a 'distinguished_name' specified."
  }
}

# Validate that users requiring an IDP have one set.
check "idp_users_have_idp_id" {
  assert {
    condition = alltrue([
      for k, v in var.users :
      !contains(["SAML", "LDAP"], v.user_type) || v.idp_id != null
    ])
    error_message = "SAML and LDAP users should have an 'idp_id' specified."
  }
}

# Validate that local users have a password.
# References local.users so the password (supplied via the sensitive
# var.user_passwords map and merged in locals) is included in the check.
check "local_users_have_password" {
  assert {
    condition = alltrue([
      for k, v in local.users :
      v.user_type != "LOCAL" || v.password != null
    ])
    error_message = "LOCAL users should have a 'password' specified."
  }
}
