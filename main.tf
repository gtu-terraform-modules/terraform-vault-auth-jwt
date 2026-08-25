resource "vault_jwt_auth_backend" "this" {
  type            = "jwt"
  path            = var.path
  description     = var.description
  disable_remount = var.disable_remount
  local           = var.local

  oidc_discovery_url     = var.oidc_discovery_url
  oidc_discovery_ca_pem  = var.oidc_discovery_ca_pem
  jwks_url               = var.jwks_url
  jwks_ca_pem            = var.jwks_ca_pem
  jwks_pairs             = var.jwks_pairs
  jwt_validation_pubkeys = var.jwt_validation_pubkeys
  jwt_supported_algs     = var.jwt_supported_algs

  bound_issuer = var.bound_issuer
  default_role = var.default_role

  dynamic "tune" {
    for_each = var.tune != null ? [var.tune] : []
    content {
      listing_visibility           = tune.value.listing_visibility
      audit_non_hmac_request_keys  = tune.value.audit_non_hmac_request_keys
      audit_non_hmac_response_keys = tune.value.audit_non_hmac_response_keys
      default_lease_ttl            = tune.value.default_lease_ttl
      max_lease_ttl                = tune.value.max_lease_ttl
      passthrough_request_headers  = tune.value.passthrough_request_headers
      allowed_response_headers     = tune.value.allowed_response_headers
      token_type                   = tune.value.token_type
    }
  }
}

resource "vault_jwt_auth_backend_role" "this" {
  for_each = var.roles

  backend   = vault_jwt_auth_backend.this.path
  role_name = each.key
  role_type = "jwt"

  user_claim                   = each.value.user_claim
  user_claim_json_pointer      = each.value.user_claim_json_pointer
  bound_audiences              = each.value.bound_audiences
  bound_subject                = each.value.bound_subject
  bound_claims                 = each.value.bound_claims
  bound_claims_type            = each.value.bound_claims_type
  disable_bound_claims_parsing = each.value.disable_bound_claims_parsing
  claim_mappings               = each.value.claim_mappings
  groups_claim                 = each.value.groups_claim

  clock_skew_leeway = each.value.clock_skew_leeway
  expiration_leeway = each.value.expiration_leeway
  not_before_leeway = each.value.not_before_leeway

  token_ttl               = each.value.token_ttl
  token_max_ttl           = each.value.token_max_ttl
  token_period            = each.value.token_period
  token_policies          = each.value.token_policies
  token_bound_cidrs       = each.value.token_bound_cidrs
  token_explicit_max_ttl  = each.value.token_explicit_max_ttl
  token_no_default_policy = each.value.token_no_default_policy
  token_num_uses          = each.value.token_num_uses
  token_type              = each.value.token_type
  alias_metadata          = each.value.alias_metadata
}
