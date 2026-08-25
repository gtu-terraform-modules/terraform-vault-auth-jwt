variable "path" {
  description = "Path where the JWT auth backend is mounted"
  type        = string
  default     = "jwt"
}

variable "description" {
  description = "Human-friendly description of the auth backend"
  type        = string
  default     = null
}

variable "disable_remount" {
  description = "If set, opts out of mount migration on path updates"
  type        = bool
  default     = null
}

variable "local" {
  description = "Specifies if the auth method is local only, not replicated to other clusters"
  type        = bool
  default     = null
}

variable "tune" {
  # NOTE: Vault preserves tune settings even when this block is removed from config.
  # Removing tune from Terraform will show "no changes" but the values remain in Vault (silent drift).
  # To reset tune settings, explicitly set them back to their defaults.
  description = "Configuration for the auth backend's tune block"
  type = object({
    listing_visibility           = optional(string)
    audit_non_hmac_request_keys  = optional(list(string))
    audit_non_hmac_response_keys = optional(list(string))
    default_lease_ttl            = optional(string)
    max_lease_ttl                = optional(string)
    passthrough_request_headers  = optional(list(string))
    allowed_response_headers     = optional(list(string))
    token_type                   = optional(string)
  })
  default = null
}

variable "jwt_validation_pubkeys" {
  description = "List of PEM-encoded public keys used to validate JWT signatures locally. Requires no network access from Vault to the token issuer"
  type        = list(string)
  default     = null

  validation {
    condition = length([
      for source in [
        var.jwt_validation_pubkeys,
        var.jwks_url,
        var.jwks_pairs,
        var.oidc_discovery_url,
      ] : source if source != null
    ]) == 1
    error_message = "Exactly one signature validation source must be set: jwt_validation_pubkeys, jwks_url, jwks_pairs, or oidc_discovery_url."
  }
}

variable "jwks_url" {
  description = "JWKS URL used to validate JWT signatures. Vault fetches the keys from this endpoint, so it must be reachable from Vault"
  type        = string
  default     = null
}

variable "jwks_ca_pem" {
  description = "CA certificate or chain, in PEM format, used to validate the TLS connection to jwks_url. If unset, system certificates are used. Cannot be combined with jwks_pairs"
  type        = string
  default     = null

  validation {
    condition     = var.jwks_ca_pem == null || var.jwks_url != null
    error_message = "jwks_ca_pem is only valid together with jwks_url."
  }
}

variable "jwks_pairs" {
  description = "List of JWKS URL and optional CA certificate pairs, as maps with keys jwks_url and jwks_ca_pem. Requires Vault 1.16+. Cannot be combined with jwks_url or jwks_ca_pem"
  type        = list(map(string))
  default     = null
}

variable "oidc_discovery_url" {
  description = "OIDC discovery URL, without any .well-known component, used to discover the signing keys. Valid for a jwt-type backend as a key source only -- it does not enable the OIDC login flow"
  type        = string
  default     = null
}

variable "oidc_discovery_ca_pem" {
  description = "CA certificate or chain, in PEM format, used to validate the TLS connection to oidc_discovery_url. If unset, system certificates are used"
  type        = string
  default     = null

  validation {
    condition     = var.oidc_discovery_ca_pem == null || var.oidc_discovery_url != null
    error_message = "oidc_discovery_ca_pem is only valid together with oidc_discovery_url."
  }
}

variable "jwt_supported_algs" {
  description = "List of signing algorithms accepted for JWTs (e.g. RS256, ES256). If unset, Vault accepts its own default set"
  type        = list(string)
  default     = null
}

variable "bound_issuer" {
  description = "The value against which to match the iss claim in a JWT"
  type        = string
  default     = null
}

variable "default_role" {
  description = "The default role to use if none is provided during login"
  type        = string
  default     = null
}

variable "roles" {
  # NOTE: bound_audiences is optional here because Vault only requires it for tokens
  # that carry an aud claim -- which is the typical case. Leave it unset only for an
  # issuer whose tokens genuinely have no audience.
  description = "Map of JWT roles to create. Key is the role name"
  type = map(object({
    user_claim                   = string
    user_claim_json_pointer      = optional(bool)
    bound_audiences              = optional(list(string))
    bound_subject                = optional(string)
    bound_claims                 = optional(map(string))
    bound_claims_type            = optional(string)
    disable_bound_claims_parsing = optional(bool)
    claim_mappings               = optional(map(string))
    groups_claim                 = optional(string)
    clock_skew_leeway            = optional(number)
    expiration_leeway            = optional(number)
    not_before_leeway            = optional(number)
    token_ttl                    = optional(number)
    token_max_ttl                = optional(number)
    token_period                 = optional(number)
    token_policies               = optional(list(string))
    token_bound_cidrs            = optional(list(string))
    token_explicit_max_ttl       = optional(number)
    token_no_default_policy      = optional(bool)
    token_num_uses               = optional(number)
    token_type                   = optional(string)
    alias_metadata               = optional(map(string))
  }))
  default = {}
}
