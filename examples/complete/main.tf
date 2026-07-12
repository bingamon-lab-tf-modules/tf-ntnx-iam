##################################################
# Nutanix IAM Module - Complete Example
##################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 2.4.2"
    }
  }
}

provider "nutanix" {
  username = var.nutanix_username
  password = var.nutanix_password
  endpoint = var.nutanix_endpoint
  insecure = var.nutanix_insecure
}

##################################################
# IAM Module
##################################################

module "iam" {
  source = "../../module"

  # Users
  users = {
    admin = {
      username     = "admin@example.com"
      user_type    = "LOCAL"
      display_name = "Administrator"
      first_name   = "Admin"
      last_name    = "User"
      email_id     = "admin@example.com"
      status       = "ACTIVE"
    }

    terraform_sa = {
      username    = "terraform-service-account"
      user_type   = "SERVICE_ACCOUNT"
      email_id    = "terraform@example.com"
      description = "Service account for Terraform automation"
    }
  }

  # User passwords are supplied via a dedicated sensitive map, keyed by the
  # same map key as 'users'. The 'users' variable itself has no password
  # attribute.
  user_passwords = {
    admin = var.admin_password
  }

  # User Groups (requires existing IDP)
  user_groups = {}

  # Custom Roles. The role is only created when at least one operation
  # external ID is supplied, as every role requires one or more operations.
  roles = length(var.vm_viewer_operations) > 0 ? {
    vm_viewer = {
      display_name = "VM Viewer"
      description  = "Can view virtual machines only"
      operations   = var.vm_viewer_operations
    }
  } : {}

  # Directory Services (LDAP/AD)
  directory_services          = var.directory_services
  directory_service_passwords = var.directory_service_passwords

  # SAML Identity Providers
  saml_identity_providers = var.saml_identity_providers
}
