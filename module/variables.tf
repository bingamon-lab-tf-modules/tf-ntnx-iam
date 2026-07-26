##################################################
# Users
##################################################

variable "users" {
  description = "A map of users to manage in Nutanix."
  type = map(object({
    username       = string
    user_type      = string # LOCAL, SAML, LDAP, EXTERNAL, SERVICE_ACCOUNT
    display_name   = optional(string, null)
    first_name     = optional(string, null)
    middle_initial = optional(string, null)
    last_name      = optional(string, null)
    email_id       = optional(string, null)
    # As with user_groups: 'directory_service' is a key into
    # var.directory_services and is resolved to that service's ext_id, while
    # 'idp_id' takes a literal UUID for a provider managed elsewhere.
    idp_id                  = optional(string, null)
    directory_service       = optional(string, null)
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

  validation {
    condition = alltrue([
      for k, v in var.users :
      v.username != null && v.username != ""
    ])
    error_message = "User 'username' is required and must be a non-empty string."
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
    group_type = string # LDAP, SAML
    # Identity provider for this group. Supply EXACTLY ONE of:
    #   directory_service — key into var.directory_services, resolved to that
    #     service's ext_id after it is created. Use this for a directory this
    #     module manages, so no UUID has to be copied between applies.
    #   idp_id — a literal UUID. Escape hatch for a directory service or SAML
    #     provider that already exists and is not managed here.
    idp_id             = optional(string, null)
    directory_service  = optional(string, null)
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

  validation {
    condition = alltrue([
      for k, v in var.user_groups :
      (v.idp_id != null) != (v.directory_service != null)
    ])
    error_message = "Each user group must set exactly one of 'idp_id' or 'directory_service', not both and not neither."
  }

  validation {
    condition = alltrue([
      for k, v in var.user_groups :
      v.directory_service == null || contains(keys(var.directory_services), coalesce(v.directory_service, ""))
    ])
    error_message = "User group 'directory_service' must be a key in var.directory_services."
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
      v.display_name != null && v.display_name != ""
    ])
    error_message = "Role 'display_name' is required and must be a non-empty string."
  }

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
      v.name != null && v.name != "" && v.url != null && v.url != ""
    ])
    error_message = "Directory service 'name' and 'url' are required and must be non-empty strings."
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

  validation {
    condition = alltrue([
      for k, v in var.saml_identity_providers :
      v.idp_metadata == null || v.idp_metadata.name_id_policy_format == null || contains(
        ["emailAddress", "encrypted", "unspecified", "transient", "WindowsDomainQualifiedName", "X509SubjectName", "kerberos", "persistent", "entity"],
        v.idp_metadata.name_id_policy_format
      )
    ])
    error_message = "SAML IDP 'idp_metadata.name_id_policy_format' must be one of: emailAddress, encrypted, unspecified, transient, WindowsDomainQualifiedName, X509SubjectName, kerberos, persistent, entity."
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

##################################################
# Authorization Policies
##################################################

variable "authorization_policies" {
  description = <<-EOT
    A map of authorization policies (role bindings) to manage in Nutanix. Each
    entry binds a role to one or more identities (users/groups) over one or more
    entity scopes — the v2 replacement for legacy v3 access_control_policy.

    'role' is the ext_id (UUID) of the role to bind. 'identities' and 'entities'
    are lists of provider 'reserved' filter-expression strings (JSON), mirroring
    the nutanix_authorization_policy_v2 schema, e.g.
      identities = ["{\"user\":{\"uuid\":{\"anyof\":[\"<user-uuid>\"]}}}"]
      entities   = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"]
  EOT
  type = map(object({
    display_name              = string
    role                      = string
    description               = optional(string, null)
    authorization_policy_type = optional(string, null)
    identities                = optional(list(string), [])
    entities                  = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.authorization_policies :
      v.display_name != null && v.display_name != ""
    ])
    error_message = "Authorization policy 'display_name' is required and must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for k, v in var.authorization_policies :
      v.role != null && v.role != ""
    ])
    error_message = "Authorization policy 'role' is required and must be a non-empty string (a role ext_id)."
  }

  validation {
    condition = alltrue([
      for k, v in var.authorization_policies :
      length(v.identities) > 0
    ])
    error_message = "Each authorization policy must bind at least one identity."
  }

  # The provider requires at least one entity scope block (min_items = 1); guard
  # here so a missing scope fails at plan with a clear message rather than at apply.
  validation {
    condition = alltrue([
      for k, v in var.authorization_policies :
      length(v.entities) > 0
    ])
    error_message = "Each authorization policy must reference at least one entity scope."
  }

  validation {
    condition = alltrue([
      for k, v in var.authorization_policies :
      v.authorization_policy_type == null || contains(
        ["USER_DEFINED", "PREDEFINED_READ_ONLY", "PREDEFINED_UPDATE_IDENTITY_ONLY", "SERVICE_DEFINED_READ_ONLY", "SERVICE_DEFINED"],
        v.authorization_policy_type
      )
    ])
    error_message = "Authorization policy 'authorization_policy_type' must be one of: USER_DEFINED, PREDEFINED_READ_ONLY, PREDEFINED_UPDATE_IDENTITY_ONLY, SERVICE_DEFINED_READ_ONLY, SERVICE_DEFINED."
  }
}

##################################################
# User API Keys
##################################################

variable "user_keys" {
  description = <<-EOT
    A map of API keys to issue for users (typically SERVICE_ACCOUNT users) via
    nutanix_user_key_v2. Each entry names the key and points at the target user;
    the module resolves the user reference to an ext_id.

    Reference the target user with EITHER 'user' (the map key of a user managed in
    'var.users', or the username of a managed/pre-existing user) OR 'user_ext_id'
    (an explicit ext_id for a pre-existing user). 'key_type' is 'API_KEY'
    (identification api_key material) or 'OBJECT_KEY' (access/secret key pair).

    The generated key material is computed and never written back to config; it is
    exposed only through the sensitive 'user_keys' output and lives in state.
  EOT
  type = map(object({
    name        = string
    user        = optional(string, null) # map key or username of the target user
    user_ext_id = optional(string, null) # explicit ext_id override (pre-existing users)
    key_type    = optional(string, "API_KEY")
    expiry_time = optional(string, null) # RFC3339, e.g. "2027-01-01T00:00:00Z"
    description = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.user_keys :
      v.name != null && v.name != ""
    ])
    error_message = "User key 'name' is required and must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for k, v in var.user_keys :
      (v.user != null && v.user != "") || (v.user_ext_id != null && v.user_ext_id != "")
    ])
    error_message = "Each user key must reference a target user via 'user' (map key or username) or 'user_ext_id'."
  }

  validation {
    condition = alltrue([
      for k, v in var.user_keys :
      contains(["API_KEY", "OBJECT_KEY"], v.key_type)
    ])
    error_message = "User key 'key_type' must be one of: API_KEY, OBJECT_KEY."
  }

  # 'expiry_time', when set, must be a valid RFC3339 timestamp so it round-trips
  # to the provider's expiry_time field rather than failing at apply.
  validation {
    condition = alltrue([
      for k, v in var.user_keys :
      v.expiry_time == null || can(formatdate("YYYY-MM-DD", v.expiry_time))
    ])
    error_message = "User key 'expiry_time' must be an RFC3339 timestamp, e.g. \"2027-01-01T00:00:00Z\"."
  }
}

variable "user_key_revocations" {
  description = <<-EOT
    A map of user-key revocations to apply via nutanix_user_key_revoke_v2. This is
    an IMPERATIVE, ONE-SHOT action, not desired state: applying an entry revokes
    the named key once; changing an entry's 'ext_id' triggers a new revoke; and
    removing/destroying an entry does NOT un-revoke the key (revocation is
    irreversible). Keep this map independent of 'var.user_keys' — a key is not
    revoked automatically when its 'user_keys' entry is destroyed.

    'ext_id' is the ext_id of the key to revoke. Reference the owning user with
    'user' (map key or username) or 'user_ext_id', same as 'var.user_keys'.
  EOT
  type = map(object({
    ext_id      = string # ext_id of the key to revoke
    user        = optional(string, null)
    user_ext_id = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.user_key_revocations :
      v.ext_id != null && v.ext_id != ""
    ])
    error_message = "User key revocation 'ext_id' (the key to revoke) is required and must be a non-empty string."
  }

  validation {
    condition = alltrue([
      for k, v in var.user_key_revocations :
      (v.user != null && v.user != "") || (v.user_ext_id != null && v.user_ext_id != "")
    ])
    error_message = "Each user key revocation must reference the owning user via 'user' (map key or username) or 'user_ext_id'."
  }
}

##################################################
# Data Lookups (gated)
##################################################

variable "enable_data_lookups" {
  description = "When true, enable the introspection data sources (IAM operations/permissions catalog and existing authorization policies). Disabled by default so a normal plan makes no discovery read calls; enable only when resolving operation ext_ids or auditing existing policies."
  type        = bool
  default     = false
}

variable "operation_lookup_ext_ids" {
  description = "Ext IDs of specific IAM operations (permissions) to resolve individually via the singular nutanix_operation_v2 data source. Only read when 'enable_data_lookups' is true. Defaults to an empty list so no per-operation lookups occur."
  type        = list(string)
  default     = []
}

variable "user_key_lookup_user_ext_ids" {
  description = "Ext IDs of users whose issued API keys should be enumerated via the nutanix_user_keys_v2 data source (the data source requires a user ext_id per query). Only read when 'enable_data_lookups' is true. Defaults to an empty list so no key-inventory reads occur."
  type        = list(string)
  default     = []
}
