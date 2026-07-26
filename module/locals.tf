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

  ##################################################
  # User API Keys
  ##################################################

  # ext_id of every module-managed user, indexed by the 'var.users' map key.
  # Values are known-after-apply (the resource ext_id is computed).
  managed_user_ext_ids_by_key = { for k, u in nutanix_users_v2.user : k => u.ext_id }

  # ext_id of every module-managed user, indexed by username (a known input),
  # so a user key can reference its owner by username as well as by map key.
  managed_user_ext_ids_by_username = { for k, u in nutanix_users_v2.user : u.username => u.ext_id }

  # ext_id of pre-existing users, indexed by username, from the ungated
  # existing-users data source. Used as the fallback when a user key references
  # a user that this module does not manage.
  existing_user_ext_ids_by_username = {
    for u in data.nutanix_users_v2.existing_users.users : u.username => u.ext_id
  }

  # Resolve each user key's target user to an ext_id: an explicit 'user_ext_id'
  # wins; otherwise 'user' is matched against managed users (by map key, then by
  # username) and finally against pre-existing users (by username). Unresolved
  # references stay null and are surfaced by the check in checks.tf.
  user_keys = {
    for k, v in var.user_keys : k => merge(v, {
      user_ext_id = (v.user_ext_id != null && v.user_ext_id != "") ? v.user_ext_id : lookup(
        local.managed_user_ext_ids_by_key, v.user, lookup(
          local.managed_user_ext_ids_by_username, v.user, lookup(
      local.existing_user_ext_ids_by_username, v.user, null)))
    })
  }

  # Same owner-resolution for revocations. 'ext_id' (the key being revoked) is
  # carried through untouched.
  user_key_revocations = {
    for k, v in var.user_key_revocations : k => merge(v, {
      user_ext_id = (v.user_ext_id != null && v.user_ext_id != "") ? v.user_ext_id : lookup(
        local.managed_user_ext_ids_by_key, v.user, lookup(
          local.managed_user_ext_ids_by_username, v.user, lookup(
      local.existing_user_ext_ids_by_username, v.user, null)))
    })
  }

  ##################################################
  # Authorization policies: role and identity resolution
  ##################################################

  # Distinct role display names to look up. Drives the data.nutanix_roles_v2
  # fan-out, so a plan with no 'role_name' in play issues no role queries.
  authz_role_names = toset([
    for k, v in var.authorization_policies : v.role_name
    if v.role_name != null && v.role_name != ""
  ])

  # Identity filter strings per policy, in the shape Prism Central expects.
  # Group membership is expressed as user.group — NOT a top-level "group" key
  # (confirmed against a live PC's built-in policies). Raw 'identities' entries
  # are appended verbatim so an unusual filter is still expressible.
  authz_identities = {
    for k, v in var.authorization_policies : k => concat(
      length(v.user_group_keys) > 0 ? [
        jsonencode({ user = { group = { anyof = [
          for g in v.user_group_keys : nutanix_user_groups_v2.group[g].ext_id
        ] } } })
      ] : [],
      length(v.user_keys) > 0 ? [
        jsonencode({ user = { uuid = { anyof = [
          for u in v.user_keys : nutanix_users_v2.user[u].ext_id
        ] } } })
      ] : [],
      v.identities,
    )
  }

  # Role ext_id per policy. Exactly one source is set (enforced by variable
  # validation), so the precedence here never has to arbitrate a conflict.
  authz_roles = {
    for k, v in var.authorization_policies : k => (
      v.role_name != null && v.role_name != ""
      ? one(data.nutanix_roles_v2.role_by_name[v.role_name].roles[*].ext_id)
      : v.role_key != null && v.role_key != ""
      ? nutanix_roles_v2.role[v.role_key].ext_id
      : v.role
    )
  }
}
