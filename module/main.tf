##################################################
# Users
##################################################

resource "nutanix_users_v2" "user" {
  for_each = local.users

  username       = each.value.username
  user_type      = each.value.user_type
  display_name   = each.value.display_name
  first_name     = each.value.first_name
  middle_initial = each.value.middle_initial
  last_name      = each.value.last_name
  email_id       = each.value.email_id
  password       = each.value.password
  idp_id         = each.value.idp_id
  locale         = each.value.locale
  region         = each.value.region
  # NOTE: is_force_reset_password is not supported by the nutanix provider
  # (verified unsupported in 2.4.2 via `tofu validate`). A validation guard on
  # var.users errors if a caller sets it, so the value can't be silently lost.
  # is_force_reset_password = each.value.is_force_reset_password
  status      = each.value.status
  description = each.value.description
}

##################################################
# User Groups
##################################################

resource "nutanix_user_groups_v2" "group" {
  for_each = var.user_groups

  group_type         = each.value.group_type
  idp_id             = each.value.idp_id
  name               = each.value.name
  distinguished_name = each.value.distinguished_name
}

##################################################
# Roles
##################################################

resource "nutanix_roles_v2" "role" {
  for_each = var.roles

  display_name = each.value.display_name
  description  = each.value.description
  operations   = each.value.operations
}

##################################################
# Directory Services
##################################################

resource "nutanix_directory_services_v2" "directory_service" {
  for_each = local.directory_services

  name                = each.value.name
  url                 = each.value.url
  secondary_urls      = length(each.value.secondary_urls) > 0 ? each.value.secondary_urls : null
  domain_name         = each.value.domain_name
  directory_type      = each.value.directory_type
  group_search_type   = each.value.group_search_type
  white_listed_groups = length(each.value.white_listed_groups) > 0 ? each.value.white_listed_groups : null

  service_account {
    username = each.value.service_account.username
    password = each.value.service_account.password
  }

  dynamic "open_ldap_configuration" {
    for_each = each.value.open_ldap_configuration != null ? [each.value.open_ldap_configuration] : []
    content {
      user_configuration {
        user_object_class  = open_ldap_configuration.value.user_configuration.user_object_class
        user_search_base   = open_ldap_configuration.value.user_configuration.user_search_base
        username_attribute = open_ldap_configuration.value.user_configuration.username_attribute
      }
      user_group_configuration {
        group_object_class           = open_ldap_configuration.value.user_group_configuration.group_object_class
        group_search_base            = open_ldap_configuration.value.user_group_configuration.group_search_base
        group_member_attribute       = open_ldap_configuration.value.user_group_configuration.group_member_attribute
        group_member_attribute_value = open_ldap_configuration.value.user_group_configuration.group_member_attribute_value
      }
    }
  }

  lifecycle {
    ignore_changes = [
      service_account[0].password,
    ]
  }
}

##################################################
# SAML Identity Providers
##################################################

resource "nutanix_saml_identity_providers_v2" "saml_idp" {
  for_each = var.saml_identity_providers

  name = each.value.name
  # NOTE: username_attr / email_attr / groups_attr / custom_attr are not
  # supported by the nutanix provider (verified unsupported in 2.4.2 via
  # `tofu validate`). Validation guards on var.saml_identity_providers error if
  # a caller sets any of them, so the values can't be silently lost.
  # username_attr = each.value.username_attr
  # email_attr    = each.value.email_attr
  # groups_attr   = each.value.groups_attr
  groups_delim  = each.value.groups_delim
  entity_issuer = each.value.entity_issuer
  # custom_attr   = length(each.value.custom_attr) > 0 ? each.value.custom_attr : null

  is_signed_authn_req_enabled = each.value.is_signed_authn_req_enabled
  idp_metadata_url            = each.value.idp_metadata_url
  idp_metadata_xml            = each.value.idp_metadata_xml

  dynamic "idp_metadata" {
    for_each = each.value.idp_metadata != null ? [each.value.idp_metadata] : []
    content {
      entity_id             = idp_metadata.value.entity_id
      login_url             = idp_metadata.value.login_url
      logout_url            = idp_metadata.value.logout_url
      error_url             = idp_metadata.value.error_url
      certificate           = idp_metadata.value.certificate
      name_id_policy_format = idp_metadata.value.name_id_policy_format
    }
  }
}

##################################################
# Authorization Policies
##################################################

resource "nutanix_authorization_policy_v2" "authorization_policy" {
  for_each = var.authorization_policies

  display_name              = each.value.display_name
  role                      = each.value.role
  description               = each.value.description
  authorization_policy_type = each.value.authorization_policy_type

  dynamic "identities" {
    for_each = each.value.identities
    content {
      reserved = identities.value
    }
  }

  dynamic "entities" {
    for_each = each.value.entities
    content {
      reserved = entities.value
    }
  }
}
