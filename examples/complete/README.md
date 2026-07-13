# Complete IAM Example

This example demonstrates the full capabilities of the tf-ntnx-iam module.

## Features Demonstrated

- Local user creation (password supplied via the dedicated `user_passwords` map)
- Service account creation
- Custom role definition
- Directory service integration (LDAP/AD)
- SAML identity provider configuration

## Usage

1. Create a `terraform.tfvars` file with the required values
2. Run the following commands:

```bash
tofu init
tofu plan
tofu apply
```

## Required Variables

| Variable           | Description                 |
| ------------------ | --------------------------- |
| `nutanix_username` | Prism Central username      |
| `nutanix_password` | Prism Central password      |
| `nutanix_endpoint` | Prism Central endpoint      |
| `admin_password`   | Password for the admin user |

## Optional Variables

| Variable                      | Description                                     | Default |
| ----------------------------- | ----------------------------------------------- | ------- |
| `nutanix_insecure`            | Allow insecure SSL                              | `false` |
| `vm_viewer_operations`        | Operation external IDs for the VM Viewer role   | `[]`    |
| `directory_services`          | Directory services config                       | `{}`    |
| `directory_service_passwords` | Directory service account passwords (sensitive) | `{}`    |
| `saml_identity_providers`     | SAML IDP config                                 | `{}`    |

## Notes

- User passwords are never set inline on `users`; they are passed through the
  sensitive `user_passwords` map, keyed by the same map key as `users`.
- Directory service account passwords follow the same pattern via
  `directory_service_passwords`.
- The `vm_viewer` role is only created when `vm_viewer_operations` contains at
  least one operation external ID, as every role requires one or more
  operations.
