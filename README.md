# terraform-vault-auth-jwt

Terraform module for configuring [JWT Auth](https://developer.hashicorp.com/vault/docs/auth/jwt) in Vault.

Creates a JWT auth backend and optionally provisions roles. Unlike the OIDC auth
method, JWT auth validates token signatures directly and performs no interactive
login flow, so a client authenticates by presenting a JWT it already holds.

For the Kubernetes case this means Vault verifies a projected ServiceAccount token
by its signature alone -- no TokenReview API call, and therefore no token reviewer
JWT and no network path from Vault to the Kubernetes API server. See
[terraform-vault-auth-kubernetes](../terraform-vault-auth-kubernetes) for the
TokenReview-based alternative.

## Usage

Exactly one signature validation source must be set: `jwt_validation_pubkeys`,
`jwks_url`, `jwks_pairs`, or `oidc_discovery_url`.

```hcl
module "vault_jwt_auth" {
  source = "git::https://github.com/your-org/gtu-terraform-modules.git//terraform-vault-auth-jwt"

  path                   = "jwt"
  bound_issuer           = "https://issuer.example.com"
  jwt_validation_pubkeys = [file("${path.module}/signing-key.pub")]

  roles = {
    "my-app" = {
      user_claim      = "sub"
      bound_audiences = ["vault"]
      bound_subject   = "system:serviceaccount:my-namespace:my-app"
      token_policies  = ["my-app-policy"]
      token_ttl       = 3600
    }
  }
}
```

### Fetching keys from a JWKS endpoint

Use this when the signing keys rotate and you would rather have Vault fetch them
than pin them in Terraform. Vault must be able to reach the endpoint.

```hcl
module "vault_jwt_auth" {
  source = "git::https://github.com/your-org/gtu-terraform-modules.git//terraform-vault-auth-jwt"

  path         = "jwt"
  jwks_url     = "https://issuer.example.com/openid/v1/jwks"
  jwks_ca_pem  = file("${path.module}/issuer-ca.pem")
  bound_issuer = "https://issuer.example.com"

  roles = {
    "ci-pipeline" = {
      user_claim      = "sub"
      bound_audiences = ["vault"]
      bound_subject   = "system:serviceaccount:ci:ci-runner"
      token_policies  = ["ci-policy"]
      token_ttl       = 3600
    }
  }
}
```

## Notes

- `bound_audiences` is required by Vault for any token that carries an `aud` claim,
  which is the typical case. The module leaves it optional so an issuer whose tokens
  genuinely have no audience is still expressible.
- `bound_subject` matches the `sub` claim exactly. Kubernetes ServiceAccount tokens
  use `system:serviceaccount:<namespace>:<name>`.
- To match on nested claims instead (`bound_claims`), verify the exact claim names
  against a real token from the target cluster first -- their shape varies by
  Kubernetes version. Decode a projected token before writing the role, do not
  assume the layout.
- `clock_skew_leeway`, `expiration_leeway` and `not_before_leeway` default to 0,
  which Vault interprets as its own default rather than as "disabled". Pass -1 to
  actually disable a check.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| vault | ~> 5.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| path | Mount path for the auth backend | `string` | `"jwt"` | no |
| description | Human-friendly description of the auth backend | `string` | `null` | no |
| disable_remount | If set, opts out of mount migration on path updates | `bool` | `null` | no |
| local | If set, the auth method is local only and not replicated to other clusters | `bool` | `null` | no |
| tune | Configuration for the auth backend's tune block | `object(...)` | `null` | no |
| jwt_validation_pubkeys | PEM-encoded public keys used to validate signatures locally | `list(string)` | `null` | one of |
| jwks_url | JWKS URL Vault fetches signing keys from | `string` | `null` | one of |
| jwks_pairs | List of JWKS URL / CA certificate pairs. Requires Vault 1.16+ | `list(map(string))` | `null` | one of |
| oidc_discovery_url | OIDC discovery URL used purely as a key source; does not enable the OIDC login flow | `string` | `null` | one of |
| jwks_ca_pem | CA certificate (PEM) validating the TLS connection to `jwks_url` | `string` | `null` | no |
| oidc_discovery_ca_pem | CA certificate (PEM) validating the TLS connection to `oidc_discovery_url` | `string` | `null` | no |
| jwt_supported_algs | Signing algorithms accepted for JWTs (e.g. `RS256`, `ES256`) | `list(string)` | `null` | no |
| bound_issuer | Value to match against the `iss` claim | `string` | `null` | no |
| default_role | Default role to use if none is provided during login | `string` | `null` | no |
| roles | Map of JWT roles to create. Key is the role name | `map(object(...))` | `{}` | no |

> Exactly one of `jwt_validation_pubkeys`, `jwks_url`, `jwks_pairs`, or `oidc_discovery_url`
> must be set. `jwks_ca_pem` requires `jwks_url`, and `oidc_discovery_ca_pem` requires
> `oidc_discovery_url`. All four constraints are enforced via variable validation.

### roles object attributes

| Name | Description | Type | Required |
|------|-------------|------|----------|
| user_claim | JWT claim to use as the user name | `string` | yes |
| user_claim_json_pointer | Interpret `user_claim` as a JSON pointer for nested claims. Requires Vault 1.11+ | `bool` | no |
| bound_audiences | Audiences permitted to authenticate; required for tokens carrying an `aud` claim | `list(string)` | no |
| bound_subject | Requires the `sub` claim to equal this value | `string` | no |
| bound_claims | Map of claims that must be present and match (key → value) | `map(string)` | no |
| bound_claims_type | How `bound_claims` values are matched: `string` or `glob` | `string` | no |
| disable_bound_claims_parsing | Disable parsing of `bound_claims` values | `bool` | no |
| claim_mappings | Map of JWT claims to copy into token metadata | `map(string)` | no |
| groups_claim | JWT claim that contains the list of groups | `string` | no |
| clock_skew_leeway | Allowable clock skew for token validation (seconds; `-1` disables) | `number` | no |
| expiration_leeway | Allowable leeway on token expiration (seconds; `-1` disables) | `number` | no |
| not_before_leeway | Allowable leeway on the `nbf` claim (seconds; `-1` disables) | `number` | no |
| token_policies | List of policies to encode onto generated tokens | `list(string)` | no |
| token_ttl | Incremental lifetime for generated tokens (seconds) | `number` | no |
| token_max_ttl | Maximum lifetime for generated tokens (seconds) | `number` | no |
| token_period | If set, tokens have no max TTL and are renewed within this period (seconds) | `number` | no |
| token_bound_cidrs | CIDR blocks that can authenticate | `list(string)` | no |
| token_explicit_max_ttl | Hard cap on the lifetime of generated tokens (seconds) | `number` | no |
| token_no_default_policy | If set, the default policy will not be added to generated tokens | `bool` | no |
| token_num_uses | Maximum number of uses for a generated token (0 = unlimited) | `number` | no |
| token_type | Type of generated tokens (`service`, `batch`, `default`) | `string` | no |
| alias_metadata | Map of metadata to set on token aliases | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| jwt_auth_backend_path | Mount path of the JWT auth backend |
| jwt_auth_backend_accessor | Accessor of the JWT auth backend, used as a reference in policies |
| jwt_auth_backend_role_names | List of JWT auth backend role names created by this module |
