##################################################
# Provider Configuration
##################################################

variable "nutanix_username" {
  description = "Username for Nutanix Prism Central"
  type        = string
}

variable "nutanix_password" {
  description = "Password for Nutanix Prism Central"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Endpoint for Nutanix Prism Central"
  type        = string
}

variable "nutanix_insecure" {
  description = "Allow insecure SSL connections"
  type        = bool
  default     = false
}

##################################################
# User Configuration
##################################################

variable "admin_password" {
  description = "Password for the admin user, passed to the module via the dedicated 'user_passwords' map"
  type        = string
  sensitive   = true
}

##################################################
# Role Configuration
##################################################

variable "vm_viewer_operations" {
  description = "List of operation external IDs for the VM Viewer role. The role is only created when at least one operation is provided."
  type        = list(string)
  default     = []
}

##################################################
# Directory Services Configuration
##################################################

variable "directory_services" {
  description = "Map of directory services to configure"
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
}

variable "directory_service_passwords" {
  description = "Map of directory service (LDAP) service account passwords, keyed by the same map key as 'directory_services'"
  type        = map(string)
  default     = {}
  sensitive   = true
}

##################################################
# SAML IDP Configuration
##################################################

variable "saml_identity_providers" {
  description = "Map of SAML identity providers to configure"
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
}
