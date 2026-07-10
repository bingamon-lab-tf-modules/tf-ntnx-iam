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

  # Guard: 'is_force_reset_password' is not supported by the nutanix provider
  # (verified unsupported in 2.4.2 via `tofu validate`). The attribute is kept
  # in the schema so it is preserved when provider support lands, but this
  # validation errors if a caller sets it today rather than silently dropping it.
  validation {
    condition = alltrue([
      for k, v in var.users :
      v.is_force_reset_password == false
    ])
    error_message = "User 'is_force_reset_password' is not yet supported by the nutanix provider (>= 2.4.0). Leave it unset (false) until the provider adds support; setting it would otherwise be silently ignored."
  }
}

variable "user_passwords" {
  description = "A map of user passwords, keyed by the same map key as 'var.users'. Kept separate so the value is marked sensitive without over-masking the other (non-secret) user attributes in plan output."
  type        = map(string)
  default     = {}
  sensitive   = true
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

variable "directory_service_passwords" {
  description = "A map of directory service (LDAP) service account passwords, keyed by the same map key as 'var.directory_services'. Kept separate so the value is marked sensitive without over-masking the other (non-secret) directory service attributes in plan output."
  type        = map(string)
  default     = {}
  sensitive   = true
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

  # Security: IdP metadata must be fetched over HTTPS. Allowing plain HTTP would
  # let a network attacker substitute the signing certificate / metadata
  # (MITM), subverting the SAML trust chain.
  validation {
    condition = alltrue([
      for v in var.saml_identity_providers :
      v.idp_metadata_url == null || startswith(lower(v.idp_metadata_url), "https://")
    ])
    error_message = "SAML IDP 'idp_metadata_url' must use HTTPS. Fetching IdP metadata over plain HTTP allows signing-certificate substitution / MITM."
  }

  # When 'entity_issuer' is provided it must not be blank whitespace.
  validation {
    condition = alltrue([
      for v in var.saml_identity_providers :
      v.entity_issuer == null || length(trimspace(v.entity_issuer)) > 0
    ])
    error_message = "SAML IDP 'entity_issuer', when set, must be a non-empty string."
  }

  # Guards: username_attr / email_attr / groups_attr / custom_attr are not
  # supported by the nutanix provider (verified unsupported in 2.4.2 via
  # `tofu validate`). They remain in the schema so values are preserved when
  # provider support lands, but these validations error if a caller sets them
  # today rather than silently dropping them.
  validation {
    condition = alltrue([
      for v in var.saml_identity_providers :
      v.username_attr == null && v.email_attr == null && v.groups_attr == null
    ])
    error_message = "SAML IDP 'username_attr', 'email_attr' and 'groups_attr' are not yet supported by the nutanix provider (>= 2.4.0). Leave them unset until the provider adds support; setting them would otherwise be silently ignored."
  }

  validation {
    condition = alltrue([
      for v in var.saml_identity_providers :
      length(v.custom_attr) == 0
    ])
    error_message = "SAML IDP 'custom_attr' is not yet supported by the nutanix provider (>= 2.4.0). Leave it empty until the provider adds support; setting it would otherwise be silently ignored."
  }
}
