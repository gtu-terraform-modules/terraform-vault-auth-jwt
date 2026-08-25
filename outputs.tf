output "jwt_auth_backend_path" {
  description = "Path where the JWT auth backend is mounted"
  value       = vault_jwt_auth_backend.this.path
}

output "jwt_auth_backend_accessor" {
  description = "The accessor of the JWT auth backend, used as a reference in policies"
  value       = vault_jwt_auth_backend.this.accessor
}

output "jwt_auth_backend_role_names" {
  description = "List of JWT auth backend role names created by this module"
  value       = keys(vault_jwt_auth_backend_role.this)
}
