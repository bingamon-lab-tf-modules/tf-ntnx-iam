##################################################
# Unit Tests: User API Keys + Revocations
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

  # Existing users lookup (ungated) — empty so 'user' references resolve only
  # against module-managed users or an explicit user_ext_id in these tests.
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
}

#########################
# Tests: valid configurations
#########################

# Test 1: The default (empty) maps plan zero keys and zero revocations.
run "empty_user_keys_plans_clean" {
  command = plan

  assert {
    condition     = output.iam_summary.total_user_keys == 0
    error_message = "Expected 0 user keys for an empty configuration."
  }

  assert {
    condition     = output.iam_summary.total_user_key_revocations == 0
    error_message = "Expected 0 user key revocations for an empty configuration."
  }

  assert {
    condition     = length(output.user_key_ids) == 0
    error_message = "Expected no user_key_ids for an empty configuration."
  }
}

# Test 2: A key whose 'user' matches a module-managed SERVICE_ACCOUNT user (by
# map key) plans and its details flow through the outputs.
run "key_planned_for_managed_user" {
  command = plan

  variables {
    users = {
      svc_ci = {
        username  = "svc-ci"
        user_type = "SERVICE_ACCOUNT"
      }
    }
    user_keys = {
      ci_runner = {
        name        = "ci-runner-key"
        user        = "svc_ci"
        expiry_time = "2027-01-01T00:00:00Z"
      }
    }
  }

  assert {
    condition     = output.iam_summary.total_user_keys == 1
    error_message = "Expected exactly 1 user key."
  }

  assert {
    condition     = output.user_keys["ci_runner"].name == "ci-runner-key"
    error_message = "Expected the 'ci_runner' key name to flow through to the output."
  }

  assert {
    condition     = output.user_keys["ci_runner"].key_type == "API_KEY"
    error_message = "Expected the default key_type to be API_KEY."
  }

  assert {
    condition     = contains(keys(output.user_key_ids), "ci_runner")
    error_message = "Expected user_key_ids to contain the 'ci_runner' key."
  }
}

# Test 3: A key can target a pre-existing user by explicit user_ext_id with no
# managed users present.
run "key_planned_for_explicit_ext_id" {
  command = plan

  variables {
    user_keys = {
      external = {
        name        = "external-key"
        user_ext_id = "11111111-1111-1111-1111-111111111111"
        key_type    = "OBJECT_KEY"
      }
    }
  }

  assert {
    condition     = output.iam_summary.total_user_keys == 1
    error_message = "Expected exactly 1 user key resolved via explicit user_ext_id."
  }

  assert {
    condition     = output.user_keys["external"].key_type == "OBJECT_KEY"
    error_message = "Expected key_type OBJECT_KEY to flow through."
  }
}

# Test 4: A revocation plans as an independent action resource.
run "revocation_planned" {
  command = plan

  variables {
    user_key_revocations = {
      leaked = {
        ext_id      = "22222222-2222-2222-2222-222222222222"
        user_ext_id = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  assert {
    condition     = output.iam_summary.total_user_key_revocations == 1
    error_message = "Expected exactly 1 user key revocation."
  }

  assert {
    condition     = output.iam_summary.total_user_keys == 0
    error_message = "Expected revocations to be independent of user_keys (0 keys)."
  }
}

#########################
# Tests: user key validations
#########################

# Test 5: A blank key name must fail validation.
run "key_requires_name" {
  command = plan

  variables {
    user_keys = {
      bad = {
        name        = ""
        user_ext_id = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  expect_failures = [var.user_keys]
}

# Test 6: A key with no user reference must fail validation.
run "key_requires_user_reference" {
  command = plan

  variables {
    user_keys = {
      bad = {
        name = "no-user-key"
      }
    }
  }

  expect_failures = [var.user_keys]
}

# Test 7: An unsupported key_type must fail validation.
run "key_invalid_key_type" {
  command = plan

  variables {
    user_keys = {
      bad = {
        name        = "bad-type-key"
        user_ext_id = "11111111-1111-1111-1111-111111111111"
        key_type    = "PASSWORD"
      }
    }
  }

  expect_failures = [var.user_keys]
}

# Test 8: A malformed expiry_time must fail validation.
run "key_invalid_expiry" {
  command = plan

  variables {
    user_keys = {
      bad = {
        name        = "bad-expiry-key"
        user_ext_id = "11111111-1111-1111-1111-111111111111"
        expiry_time = "not-a-timestamp"
      }
    }
  }

  expect_failures = [var.user_keys]
}

#########################
# Tests: revocation validations
#########################

# Test 9: A revocation with a blank key ext_id must fail validation.
run "revocation_requires_ext_id" {
  command = plan

  variables {
    user_key_revocations = {
      bad = {
        ext_id      = ""
        user_ext_id = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  expect_failures = [var.user_key_revocations]
}

# Test 10: A revocation with no user reference must fail validation.
run "revocation_requires_user_reference" {
  command = plan

  variables {
    user_key_revocations = {
      bad = {
        ext_id = "22222222-2222-2222-2222-222222222222"
      }
    }
  }

  expect_failures = [var.user_key_revocations]
}
