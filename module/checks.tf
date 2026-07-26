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
      !contains(["SAML", "LDAP"], v.user_type) || v.idp_id != null || v.directory_service != null
    ])
    error_message = "SAML and LDAP users should have either an 'idp_id' or a 'directory_service' specified."
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
      length([for r in [v.role, v.role_name, v.role_key] : r if r != null && r != ""]) == 1 &&
      length(v.identities) + length(v.user_group_keys) + length(v.user_keys) > 0 &&
      length(v.entities) > 0
    ])
    error_message = "Each authorization policy should name exactly one role (role_name, role_key or role) and bind at least one identity over at least one entity scope."
  }
}

# Validate that every user key resolved its target user to an ext_id. References
# to module-managed users resolve to a known-after-apply ext_id (this check
# defers on them); a 'user' that matches no managed or pre-existing user
# resolves to null and is caught here rather than failing opaquely at apply.
check "user_keys_reference_resolvable_user" {
  assert {
    condition = alltrue([
      for k, v in local.user_keys :
      v.user_ext_id != null
    ])
    error_message = "A user key references a 'user' that matches no managed or pre-existing user. Set 'user' to a users map key/username, or provide 'user_ext_id'."
  }
}

# Same resolvability check for revocation owners.
check "user_key_revocations_reference_resolvable_user" {
  assert {
    condition = alltrue([
      for k, v in local.user_key_revocations :
      v.user_ext_id != null
    ])
    error_message = "A user key revocation references a 'user' that matches no managed or pre-existing user. Set 'user' to a users map key/username, or provide 'user_ext_id'."
  }
}
