##################################################
# Unit Tests: IAM
##################################################

#########################
# Provider
#########################

provider "nutanix" {
  username     = "dummy"
  password     = "dummy"
  endpoint     = "dummy.local"
  port         = 9440
  insecure     = true
  wait_timeout = 1
}

#########################
# Mock Data (Nutanix Provider)
#########################

mock_provider "nutanix" {

  # Existing users lookup
  mock_data "nutanix_users_v2" {
    defaults = {
      users = []
    }
  }

  # Existing roles lookup
  mock_data "nutanix_roles_v2" {
    defaults = {
      roles = []
    }
  }

  # Existing directory services lookup
  mock_data "nutanix_directory_services_v2" {
    defaults = {
      directory_services = []
    }
  }

  # Existing SAML identity providers lookup
  mock_data "nutanix_saml_identity_providers_v2" {
    defaults = {
      identity_providers = []
    }
  }

  # Available operations lookup (for role creation)
  mock_data "nutanix_operations_v2" {
    defaults = {
      operations = []
    }
  }
}

#########################
# Tests: valid configurations
#########################

# Test 1: Empty configuration plans clean with zero resources.
run "empty_config_plans_clean" {
  command = plan

  assert {
    condition     = output.iam_summary.total_users == 0
    error_message = "Expected 0 users for an empty configuration."
  }

  assert {
    condition     = output.iam_summary.total_user_groups == 0
    error_message = "Expected 0 user groups for an empty configuration."
  }

  assert {
    condition     = output.iam_summary.total_roles == 0
    error_message = "Expected 0 roles for an empty configuration."
  }

  assert {
    condition     = output.iam_summary.total_directory_services == 0
    error_message = "Expected 0 directory services for an empty configuration."
  }

  assert {
    condition     = output.iam_summary.total_saml_idps == 0
    error_message = "Expected 0 SAML IDPs for an empty configuration."
  }
}

# Test 2: A valid local user and custom role plan and output assertions hold.
run "valid_user_and_role" {
  command = plan

  variables {
    users = {
      admin = {
        username     = "admin@corp.example.com"
        user_type    = "LOCAL"
        display_name = "Platform Administrator"
        status       = "ACTIVE"
      }
    }
    user_passwords = {
      admin = "dummy-password"
    }
    roles = {
      vm_operator = {
        display_name = "VM Operator"
        operations   = ["00000000-0000-0000-0000-000000000001"]
      }
    }
  }

  assert {
    condition     = output.iam_summary.total_users == 1
    error_message = "Expected exactly 1 user."
  }

  assert {
    condition     = output.iam_summary.total_roles == 1
    error_message = "Expected exactly 1 role."
  }

  assert {
    condition     = output.users["admin"].user_type == "LOCAL"
    error_message = "Expected the 'admin' user to be a LOCAL user."
  }
}

# Test 3: A valid Active Directory service and SAML IDP plan and output
# assertions hold.
run "valid_directory_and_saml" {
  command = plan

  variables {
    directory_services = {
      corp_ad = {
        name           = "corp-active-directory"
        url            = "ldaps://ad.corp.example.com:636"
        domain_name    = "corp.example.com"
        directory_type = "ACTIVE_DIRECTORY"
        service_account = {
          username = "svc-nutanix@corp.example.com"
        }
      }
    }
    directory_service_passwords = {
      corp_ad = "dummy-bind-password"
    }
    saml_identity_providers = {
      okta = {
        name             = "okta-saml"
        idp_metadata_url = "https://corp.okta.com/app/exampleapp/sso/saml/metadata"
      }
    }
  }

  assert {
    condition     = output.iam_summary.total_directory_services == 1
    error_message = "Expected exactly 1 directory service."
  }

  assert {
    condition     = output.iam_summary.total_saml_idps == 1
    error_message = "Expected exactly 1 SAML IDP."
  }
}

#########################
# Tests: user validations
#########################

# Test 4: An unsupported user_type must fail validation.
run "invalid_user_type" {
  command = plan

  variables {
    users = {
      bad = {
        username  = "bad@corp.example.com"
        user_type = "ROBOT"
      }
    }
  }

  expect_failures = [var.users]
}

# Test 5: An unsupported user status must fail validation.
run "invalid_user_status" {
  command = plan

  variables {
    users = {
      bad = {
        username  = "bad@corp.example.com"
        user_type = "LOCAL"
        status    = "SUSPENDED"
      }
    }
    user_passwords = {
      bad = "dummy-password"
    }
  }

  expect_failures = [var.users]
}

# Test 6: An empty username must fail validation.
run "empty_username" {
  command = plan

  variables {
    users = {
      bad = {
        username  = ""
        user_type = "LOCAL"
      }
    }
    user_passwords = {
      bad = "dummy-password"
    }
  }

  expect_failures = [var.users]
}

# Test 7: The unsupported 'is_force_reset_password' attribute must fail
# validation (guard until the provider supports it).
run "force_reset_password_unsupported" {
  command = plan

  variables {
    users = {
      bad = {
        username                = "bad@corp.example.com"
        user_type               = "LOCAL"
        is_force_reset_password = true
      }
    }
    user_passwords = {
      bad = "dummy-password"
    }
  }

  expect_failures = [var.users]
}

#########################
# Tests: user group validations
#########################

# Test 8: An unsupported user group type must fail validation.
run "invalid_group_type" {
  command = plan

  variables {
    user_groups = {
      bad = {
        group_type = "OKTA"
        idp_id     = "00000000-0000-0000-0000-0000000000aa"
      }
    }
  }

  expect_failures = [var.user_groups]
}

#########################
# Tests: role validations
#########################

# Test 9: A role with no operations must fail validation.
run "role_requires_operations" {
  command = plan

  variables {
    roles = {
      empty = {
        display_name = "Empty Role"
        operations   = []
      }
    }
  }

  expect_failures = [var.roles]
}

# Test 10: A role with a blank display name must fail validation.
run "role_requires_display_name" {
  command = plan

  variables {
    roles = {
      blank = {
        display_name = ""
        operations   = ["00000000-0000-0000-0000-000000000001"]
      }
    }
  }

  expect_failures = [var.roles]
}

#########################
# Tests: directory service validations
#########################

# Test 11: An unsupported directory_type must fail validation.
run "invalid_directory_type" {
  command = plan

  variables {
    directory_services = {
      bad = {
        name           = "bad-directory"
        url            = "ldaps://ad.corp.example.com:636"
        domain_name    = "corp.example.com"
        directory_type = "NIS"
        service_account = {
          username = "svc-nutanix@corp.example.com"
        }
      }
    }
    directory_service_passwords = {
      bad = "dummy-bind-password"
    }
  }

  expect_failures = [var.directory_services]
}

# Test 12: An OpenLDAP directory service without 'open_ldap_configuration'
# must fail validation.
run "openldap_requires_config" {
  command = plan

  variables {
    directory_services = {
      openldap = {
        name           = "corp-openldap"
        url            = "ldaps://ldap.corp.example.com:636"
        domain_name    = "corp.example.com"
        directory_type = "OPEN_LDAP"
        service_account = {
          username = "cn=svc-nutanix,dc=corp,dc=example,dc=com"
        }
      }
    }
    directory_service_passwords = {
      openldap = "dummy-bind-password"
    }
  }

  expect_failures = [var.directory_services]
}

# Test 13: An unsupported 'group_search_type' must fail validation.
run "invalid_group_search_type" {
  command = plan

  variables {
    directory_services = {
      bad = {
        name              = "corp-active-directory"
        url               = "ldaps://ad.corp.example.com:636"
        domain_name       = "corp.example.com"
        directory_type    = "ACTIVE_DIRECTORY"
        group_search_type = "DEEP"
        service_account = {
          username = "svc-nutanix@corp.example.com"
        }
      }
    }
    directory_service_passwords = {
      bad = "dummy-bind-password"
    }
  }

  expect_failures = [var.directory_services]
}

#########################
# Tests: SAML IDP validations
#########################

# Test 14: A SAML IDP with no metadata source must fail validation.
run "saml_requires_metadata" {
  command = plan

  variables {
    saml_identity_providers = {
      bad = {
        name = "okta-saml"
      }
    }
  }

  expect_failures = [var.saml_identity_providers]
}

# Test 15: A SAML IDP metadata URL over plain HTTP must fail validation.
run "saml_metadata_url_must_be_https" {
  command = plan

  variables {
    saml_identity_providers = {
      bad = {
        name             = "okta-saml"
        idp_metadata_url = "http://corp.okta.com/app/exampleapp/sso/saml/metadata"
      }
    }
  }

  expect_failures = [var.saml_identity_providers]
}

# Test 16: An unsupported 'name_id_policy_format' must fail validation.
run "saml_invalid_name_id_policy_format" {
  command = plan

  variables {
    saml_identity_providers = {
      bad = {
        name = "okta-saml"
        idp_metadata = {
          entity_id             = "https://corp.okta.com/exampleapp"
          login_url             = "https://corp.okta.com/app/exampleapp/sso/saml"
          certificate           = "-----BEGIN CERTIFICATE-----\nMIID\n-----END CERTIFICATE-----"
          name_id_policy_format = "socialSecurityNumber"
        }
      }
    }
  }

  expect_failures = [var.saml_identity_providers]
}

# Test 17: A blank 'entity_issuer' must fail validation.
run "saml_blank_entity_issuer" {
  command = plan

  variables {
    saml_identity_providers = {
      bad = {
        name             = "okta-saml"
        entity_issuer    = "   "
        idp_metadata_url = "https://corp.okta.com/app/exampleapp/sso/saml/metadata"
      }
    }
  }

  expect_failures = [var.saml_identity_providers]
}

# Test 18: Unsupported SAML attribute mappings must fail validation (guard
# until the provider supports them).
run "saml_unsupported_attrs" {
  command = plan

  variables {
    saml_identity_providers = {
      bad = {
        name             = "okta-saml"
        username_attr    = "NameID"
        idp_metadata_url = "https://corp.okta.com/app/exampleapp/sso/saml/metadata"
      }
    }
  }

  expect_failures = [var.saml_identity_providers]
}

# Test 19: Unsupported SAML custom attributes must fail validation (guard
# until the provider supports them).
run "saml_unsupported_custom_attr" {
  command = plan

  variables {
    saml_identity_providers = {
      bad = {
        name             = "okta-saml"
        custom_attr      = ["department"]
        idp_metadata_url = "https://corp.okta.com/app/exampleapp/sso/saml/metadata"
      }
    }
  }

  expect_failures = [var.saml_identity_providers]
}
