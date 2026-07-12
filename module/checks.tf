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

# Validate that each authorization policy is a coherent role binding: it names a
# role and binds at least one identity over at least one entity scope. A binding
# missing any of the three grants nothing (or fails at apply).
check "authorization_policies_are_coherent" {
  assert {
    condition = alltrue([
      for k, v in var.authorization_policies :
      v.role != null && v.role != "" && length(v.identities) > 0 && length(v.entities) > 0
    ])
    error_message = "Each authorization policy should name a role and bind at least one identity over at least one entity scope."
  }
}
