##################################################
# Nutanix IAM Module - Example
##################################################

terraform {
  required_version = ">= 1.9.0"
}

##################################################
# Secrets (passed as variable references, never literals)
##################################################

variable "admin_password" {
  description = "Password for the local 'admin' user, supplied to the module via the sensitive 'user_passwords' map."
  type        = string
  sensitive   = true
}

variable "ad_bind_password" {
  description = "Bind password for the Active Directory service account, supplied via the sensitive 'directory_service_passwords' map."
  type        = string
  sensitive   = true
}

##################################################
# IAM Module
##################################################

module "iam" {
  source = "git::https://github.com/bingamon-lab-tf-modules/tf-ntnx-iam.git//module?ref=v0.1.0"

  # One local user. Its password is supplied via the dedicated sensitive
  # 'user_passwords' map, keyed by the same map key as 'users'.
  users = {
    admin = {
      username     = "admin@corp.example.com"
      user_type    = "LOCAL"
      display_name = "Platform Administrator"
      first_name   = "Platform"
      last_name    = "Administrator"
      email_id     = "admin@corp.example.com"
      status       = "ACTIVE"
    }
  }

  user_passwords = {
    admin = var.admin_password
  }

  # One custom role composed of operations. Operations are referenced by their
  # external IDs (look these up from the nutanix_operations_v2 data source or
  # Prism Central); the placeholders below are illustrative.
  roles = {
    vm_operator = {
      display_name = "VM Operator"
      description  = "Can view and power-manage virtual machines."
      operations = [
        "00000000-0000-0000-0000-000000000001",
        "00000000-0000-0000-0000-000000000002",
      ]
    }
  }

  # One Active Directory directory service. The service account bind password
  # is supplied via the dedicated sensitive 'directory_service_passwords' map.
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
    corp_ad = var.ad_bind_password
  }

  # One SAML identity provider, trusting IdP metadata fetched over HTTPS.
  saml_identity_providers = {
    okta = {
      name             = "okta-saml"
      idp_metadata_url = "https://corp.okta.com/app/exampleapp/sso/saml/metadata"
      entity_issuer    = "https://prism-central.corp.example.com"
    }
  }
}
