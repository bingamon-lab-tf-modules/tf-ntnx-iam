##################################################
# Unit Tests: Authorization Policies (role bindings)
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

  # Existing users lookup (ungated)
  mock_data "nutanix_users_v2" {
    defaults = {
      users = []
    }
  }

  # Existing roles lookup (ungated)
  mock_data "nutanix_roles_v2" {
    defaults = {
      roles = []
    }
  }

  # Existing directory services lookup (ungated)
  mock_data "nutanix_directory_services_v2" {
    defaults = {
      directory_services = []
    }
  }

  # Existing SAML identity providers lookup (ungated)
  mock_data "nutanix_saml_identity_providers_v2" {
    defaults = {
      identity_providers = []
    }
  }

  # Operations catalog (gated; mocked so enable_data_lookups tests are stable)
  mock_data "nutanix_operations_v2" {
    defaults = {
      operations = []
    }
  }

  # Existing authorization policies lookup (gated)
  mock_data "nutanix_authorization_policies_v2" {
    defaults = {
      auth_policies = []
    }
  }
}

#########################
# Tests: valid configurations
#########################

# Test 1: The default (empty) authorization_policies map plans zero policies.
run "empty_authorization_policies_plans_clean" {
  command = plan

  assert {
    condition     = output.iam_summary.total_authorization_policies == 0
    error_message = "Expected 0 authorization policies for an empty configuration."
  }

  assert {
    condition     = length(output.authorization_policy_ids) == 0
    error_message = "Expected no authorization_policy_ids for an empty configuration."
  }
}

# Test 2: A populated authorization_policies map plans a policy and the outputs
# carry the binding details through.
run "policy_planned_from_populated_map" {
  command = plan

  variables {
    authorization_policies = {
      lab_admins = {
        display_name              = "lab-admins"
        description               = "Cluster admin role binding for lab admins group"
        role                      = "ba250e3e-1db1-4950-917f-a9e2ea35b8e3"
        authorization_policy_type = "USER_DEFINED"
        identities                = ["{\"user\":{\"uuid\":{\"anyof\":[\"00000000-0000-0000-0000-000000000000\"]}}}"]
        entities                  = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"]
      }
    }
  }

  assert {
    condition     = output.iam_summary.total_authorization_policies == 1
    error_message = "Expected exactly 1 authorization policy."
  }

  assert {
    condition     = output.authorization_policies["lab_admins"].display_name == "lab-admins"
    error_message = "Expected the 'lab_admins' policy display_name to flow through to the output."
  }

  assert {
    condition     = output.authorization_policies["lab_admins"].role == "ba250e3e-1db1-4950-917f-a9e2ea35b8e3"
    error_message = "Expected the 'lab_admins' policy to bind the given role ext_id."
  }

  assert {
    condition     = contains(keys(output.authorization_policy_ids), "lab_admins")
    error_message = "Expected authorization_policy_ids to contain the 'lab_admins' key."
  }
}

#########################
# Tests: authorization policy validations
#########################

# Test 3: A policy with a blank role must fail validation.
run "policy_requires_role" {
  command = plan

  variables {
    authorization_policies = {
      bad = {
        display_name = "no-role"
        role         = ""
        identities   = ["{\"user\":{\"uuid\":{\"anyof\":[\"00000000-0000-0000-0000-000000000000\"]}}}"]
        entities     = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"]
      }
    }
  }

  expect_failures = [var.authorization_policies]
}

# Test 4: A policy with no identities must fail validation.
run "policy_requires_identity" {
  command = plan

  variables {
    authorization_policies = {
      bad = {
        display_name = "no-identity"
        role         = "ba250e3e-1db1-4950-917f-a9e2ea35b8e3"
        identities   = []
        entities     = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"]
      }
    }
  }

  expect_failures = [var.authorization_policies]
}

# Test 5: A policy with no entity scope must fail validation.
run "policy_requires_entity" {
  command = plan

  variables {
    authorization_policies = {
      bad = {
        display_name = "no-entity"
        role         = "ba250e3e-1db1-4950-917f-a9e2ea35b8e3"
        identities   = ["{\"user\":{\"uuid\":{\"anyof\":[\"00000000-0000-0000-0000-000000000000\"]}}}"]
        entities     = []
      }
    }
  }

  expect_failures = [var.authorization_policies]
}

# Test 6: A blank display_name must fail validation.
run "policy_requires_display_name" {
  command = plan

  variables {
    authorization_policies = {
      bad = {
        display_name = ""
        role         = "ba250e3e-1db1-4950-917f-a9e2ea35b8e3"
        identities   = ["{\"user\":{\"uuid\":{\"anyof\":[\"00000000-0000-0000-0000-000000000000\"]}}}"]
        entities     = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"]
      }
    }
  }

  expect_failures = [var.authorization_policies]
}

# Test 7: An unsupported authorization_policy_type must fail validation.
run "policy_invalid_type" {
  command = plan

  variables {
    authorization_policies = {
      bad = {
        display_name              = "bad-type"
        role                      = "ba250e3e-1db1-4950-917f-a9e2ea35b8e3"
        authorization_policy_type = "SUPER_ADMIN"
        identities                = ["{\"user\":{\"uuid\":{\"anyof\":[\"00000000-0000-0000-0000-000000000000\"]}}}"]
        entities                  = ["{\"images\":{\"*\":{\"eq\":\"*\"}}}"]
      }
    }
  }

  expect_failures = [var.authorization_policies]
}
