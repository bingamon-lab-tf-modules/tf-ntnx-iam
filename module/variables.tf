##################################################
# Users
##################################################

variable "users" {
  description = "A map of users to manage in Nutanix."
  type = map(object({
    username                = string
    user_type               = string # LOCAL, SAML, LDAP, EXTERNAL, SERVICE_ACCOUNT
    display_name            = optional(string, null)
    first_name              = optional(string, null)
    middle_initial          = optional(string, null)
    last_name               = optional(string, null)
    email_id                = optional(string, null)
    password                = optional(string, null)
    idp_id                  = optional(string, null)
    locale                  = optional(string, null)
    region                  = optional(string, null)
    is_force_reset_password = optional(bool, false)
    status                  = optional(string, "ACTIVE")
    description             = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.users :
      contains(["LOCAL", "SAML", "LDAP", "EXTERNAL", "SERVICE_ACCOUNT"], v.user_type)
    ])
    error_message = "User 'user_type' must be one of: LOCAL, SAML, LDAP, EXTERNAL, SERVICE_ACCOUNT."
  }

  validation {
    condition = alltrue([
      for k, v in var.users :
      v.status == null || contains(["ACTIVE", "INACTIVE"], v.status)
    ])
    error_message = "User 'status' must be one of: ACTIVE, INACTIVE."
  }
}

##################################################
# User Groups
##################################################

variable "user_groups" {
  description = "A map of user groups to manage in Nutanix."
  type = map(object({
    group_type         = string # LDAP, SAML
    idp_id             = string
    name               = optional(string, null)
    distinguished_name = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.user_groups :
      contains(["LDAP", "SAML"], v.group_type)
    ])
    error_message = "User group 'group_type' must be one of: LDAP, SAML."
  }
}

##################################################
# Roles
##################################################

variable "roles" {
  description = "A map of roles to manage in Nutanix."
  type = map(object({
    display_name = string
    description  = optional(string, null)
    operations   = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.roles :
      length(v.operations) > 0
    ])
    error_message = "Each role must have at least one operation."
  }
}

##################################################
# Directory Services
##################################################

variable "directory_services" {
  description = "A map of directory services to manage in Nutanix."
  type = map(object({
    name                = string
    url                 = string
    domain_name         = string
    directory_type      = string # ACTIVE_DIRECTORY, OPEN_LDAP
    secondary_urls      = optional(list(string), [])
    group_search_type   = optional(string, null)
    white_listed_groups = optional(list(string), [])

    service_account = object({
      username = string
      password = string
    })

    open_ldap_configuration = optional(object({
      user_configuration = object({
        user_object_class  = string
        user_search_base   = string
        username_attribute = string
      })
      user_group_configuration = object({
        group_object_class           = string
        group_search_base            = string
        group_member_attribute       = string
        group_member_attribute_value = string
      })
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.directory_services :
      contains(["ACTIVE_DIRECTORY", "OPEN_LDAP"], v.directory_type)
    ])
    error_message = "Directory service 'directory_type' must be one of: ACTIVE_DIRECTORY, OPEN_LDAP."
  }

  validation {
    condition = alltrue([
      for k, v in var.directory_services :
      v.directory_type == "OPEN_LDAP" ? v.open_ldap_configuration != null : true
    ])
    error_message = "OpenLDAP directory services require 'open_ldap_configuration' to be provided."
  }

  validation {
    condition = alltrue([
      for k, v in var.directory_services :
      v.group_search_type == null || contains(["NON_RECURSIVE", "RECURSIVE"], v.group_search_type)
    ])
    error_message = "Directory service 'group_search_type' must be one of: NON_RECURSIVE, RECURSIVE."
  }
}

##################################################
# SAML Identity Providers
##################################################

variable "saml_identity_providers" {
  description = "A map of SAML identity providers to manage in Nutanix."
  type = map(object({
    name                        = string
    username_attr               = optional(string, null)
    email_attr                  = optional(string, null)
    groups_attr                 = optional(string, null)
    groups_delim                = optional(string, null)
    entity_issuer               = optional(string, null)
    custom_attr                 = optional(list(string), [])
    is_signed_authn_req_enabled = optional(bool, true)

    idp_metadata_url = optional(string, null)
    idp_metadata_xml = optional(string, null)

    idp_metadata = optional(object({
      entity_id             = string
      login_url             = string
      logout_url            = optional(string, null)
      error_url             = optional(string, null)
      certificate           = string
      name_id_policy_format = optional(string, null)
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.saml_identity_providers :
      v.idp_metadata != null || v.idp_metadata_url != null || v.idp_metadata_xml != null
    ])
    error_message = "Each SAML IDP must provide at least one of: 'idp_metadata', 'idp_metadata_url', or 'idp_metadata_xml'."
  }
}
