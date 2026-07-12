# tf-ntnx-iam

## Table of Contents

## Overview

A description of the module goes here.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_nutanix"></a> [nutanix](#requirement\_nutanix) | >= 2.4.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nutanix"></a> [nutanix](#provider\_nutanix) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nutanix_authorization_policy_v2.authorization_policy](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/authorization_policy_v2) | resource |
| [nutanix_directory_services_v2.directory_service](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/directory_services_v2) | resource |
| [nutanix_roles_v2.role](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/roles_v2) | resource |
| [nutanix_saml_identity_providers_v2.saml_idp](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/saml_identity_providers_v2) | resource |
| [nutanix_user_groups_v2.group](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/user_groups_v2) | resource |
| [nutanix_users_v2.user](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/resources/users_v2) | resource |
| [nutanix_authorization_policies_v2.existing_authorization_policies](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/authorization_policies_v2) | data source |
| [nutanix_directory_services_v2.existing_directory_services](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/directory_services_v2) | data source |
| [nutanix_operation_v2.operation](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/operation_v2) | data source |
| [nutanix_operations_v2.all_operations](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/operations_v2) | data source |
| [nutanix_roles_v2.existing_roles](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/roles_v2) | data source |
| [nutanix_saml_identity_providers_v2.existing_saml_idps](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/saml_identity_providers_v2) | data source |
| [nutanix_users_v2.existing_users](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs/data-sources/users_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorization_policies"></a> [authorization\_policies](#input\_authorization\_policies) | A map of authorization policies (role bindings) to manage in Nutanix. Each<br/>entry binds a role to one or more identities (users/groups) over one or more<br/>entity scopes — the v2 replacement for legacy v3 access\_control\_policy.<br/><br/>'role' is the ext\_id (UUID) of the role to bind. 'identities' and 'entities'<br/>are lists of provider 'reserved' filter-expression strings (JSON), mirroring<br/>the nutanix\_authorization\_policy\_v2 schema, e.g.<br/>  identities = ["{\"user\":{\"uuid\":{\"anyof\":[\"<user-uuid>\"]}}}"]<br/>  entities   = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"] | <pre>map(object({<br/>    display_name              = string<br/>    role                      = string<br/>    description               = optional(string, null)<br/>    authorization_policy_type = optional(string, null)<br/>    identities                = optional(list(string), [])<br/>    entities                  = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_directory_service_passwords"></a> [directory\_service\_passwords](#input\_directory\_service\_passwords) | A map of directory service (LDAP) service account passwords, keyed by the same map key as 'var.directory\_services'. Kept separate so the value is marked sensitive without over-masking the other (non-secret) directory service attributes in plan output. | `map(string)` | `{}` | no |
| <a name="input_directory_services"></a> [directory\_services](#input\_directory\_services) | A map of directory services to manage in Nutanix. | <pre>map(object({<br/>    name                = string<br/>    url                 = string<br/>    domain_name         = string<br/>    directory_type      = string # ACTIVE_DIRECTORY, OPEN_LDAP<br/>    secondary_urls      = optional(list(string), [])<br/>    group_search_type   = optional(string, null)<br/>    white_listed_groups = optional(list(string), [])<br/><br/>    service_account = object({<br/>      username = string<br/>    })<br/><br/>    open_ldap_configuration = optional(object({<br/>      user_configuration = object({<br/>        user_object_class  = string<br/>        user_search_base   = string<br/>        username_attribute = string<br/>      })<br/>      user_group_configuration = object({<br/>        group_object_class           = string<br/>        group_search_base            = string<br/>        group_member_attribute       = string<br/>        group_member_attribute_value = string<br/>      })<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_data_lookups"></a> [enable\_data\_lookups](#input\_enable\_data\_lookups) | When true, enable the introspection data sources (IAM operations/permissions catalog and existing authorization policies). Disabled by default so a normal plan makes no discovery read calls; enable only when resolving operation ext\_ids or auditing existing policies. | `bool` | `false` | no |
| <a name="input_operation_lookup_ext_ids"></a> [operation\_lookup\_ext\_ids](#input\_operation\_lookup\_ext\_ids) | Ext IDs of specific IAM operations (permissions) to resolve individually via the singular nutanix\_operation\_v2 data source. Only read when 'enable\_data\_lookups' is true. Defaults to an empty list so no per-operation lookups occur. | `list(string)` | `[]` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | A map of roles to manage in Nutanix. | <pre>map(object({<br/>    display_name = string<br/>    description  = optional(string, null)<br/>    operations   = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_saml_identity_providers"></a> [saml\_identity\_providers](#input\_saml\_identity\_providers) | A map of SAML identity providers to manage in Nutanix. | <pre>map(object({<br/>    name                        = string<br/>    username_attr               = optional(string, null)<br/>    email_attr                  = optional(string, null)<br/>    groups_attr                 = optional(string, null)<br/>    groups_delim                = optional(string, null)<br/>    entity_issuer               = optional(string, null)<br/>    custom_attr                 = optional(list(string), [])<br/>    is_signed_authn_req_enabled = optional(bool, true)<br/><br/>    idp_metadata_url = optional(string, null)<br/>    idp_metadata_xml = optional(string, null)<br/><br/>    idp_metadata = optional(object({<br/>      entity_id             = string<br/>      login_url             = string<br/>      logout_url            = optional(string, null)<br/>      error_url             = optional(string, null)<br/>      certificate           = string<br/>      name_id_policy_format = optional(string, null)<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_user_groups"></a> [user\_groups](#input\_user\_groups) | A map of user groups to manage in Nutanix. | <pre>map(object({<br/>    group_type         = string # LDAP, SAML<br/>    idp_id             = string<br/>    name               = optional(string, null)<br/>    distinguished_name = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_user_passwords"></a> [user\_passwords](#input\_user\_passwords) | A map of user passwords, keyed by the same map key as 'var.users'. Kept separate so the value is marked sensitive without over-masking the other (non-secret) user attributes in plan output. | `map(string)` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | A map of users to manage in Nutanix. | <pre>map(object({<br/>    username                = string<br/>    user_type               = string # LOCAL, SAML, LDAP, EXTERNAL, SERVICE_ACCOUNT<br/>    display_name            = optional(string, null)<br/>    first_name              = optional(string, null)<br/>    middle_initial          = optional(string, null)<br/>    last_name               = optional(string, null)<br/>    email_id                = optional(string, null)<br/>    idp_id                  = optional(string, null)<br/>    locale                  = optional(string, null)<br/>    region                  = optional(string, null)<br/>    is_force_reset_password = optional(bool, false)<br/>    status                  = optional(string, "ACTIVE")<br/>    description             = optional(string, null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_authorization_policies"></a> [authorization\_policies](#output\_authorization\_policies) | Map of created authorization policies (role bindings) with their details. |
| <a name="output_authorization_policy_ids"></a> [authorization\_policy\_ids](#output\_authorization\_policy\_ids) | Map of authorization policy keys to their external IDs. |
| <a name="output_directory_service_ids"></a> [directory\_service\_ids](#output\_directory\_service\_ids) | Map of directory service keys to their external IDs. |
| <a name="output_directory_services"></a> [directory\_services](#output\_directory\_services) | Map of created directory services with their details. |
| <a name="output_iam_summary"></a> [iam\_summary](#output\_iam\_summary) | Summary of IAM resources managed by this module. |
| <a name="output_role_ids"></a> [role\_ids](#output\_role\_ids) | Map of role keys to their external IDs. |
| <a name="output_roles"></a> [roles](#output\_roles) | Map of created roles with their details. |
| <a name="output_saml_identity_provider_ids"></a> [saml\_identity\_provider\_ids](#output\_saml\_identity\_provider\_ids) | Map of SAML IDP keys to their external IDs. |
| <a name="output_saml_identity_providers"></a> [saml\_identity\_providers](#output\_saml\_identity\_providers) | Map of created SAML identity providers with their details. |
| <a name="output_user_group_ids"></a> [user\_group\_ids](#output\_user\_group\_ids) | Map of user group keys to their external IDs. |
| <a name="output_user_groups"></a> [user\_groups](#output\_user\_groups) | Map of created user groups with their details. |
| <a name="output_user_ids"></a> [user\_ids](#output\_user\_ids) | Map of user keys to their external IDs. |
| <a name="output_users"></a> [users](#output\_users) | Map of created users with their details. |
<!-- END_TF_DOCS -->
