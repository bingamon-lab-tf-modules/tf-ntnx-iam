config {
  # Terraform child module: data sources and locals are intentionally
  # declared ahead of being wired into resources during MVP development.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# MVP scaffolding: several data sources and filter locals are declared
# ahead of use and are wired up in later phases. Disable the unused
# declaration rule until the module implementation is complete.
rule "terraform_unused_declarations" {
  enabled = false
}
