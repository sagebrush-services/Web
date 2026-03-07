import JWTKit

/// Standard OIDC ID token payload.
///
/// Uses only claims defined in the OIDC Core specification (RFC 7519 / OpenID Connect Core 1.0).
/// No provider-specific claims (e.g. Cognito's `token_use` or `cognito:groups`) appear here,
/// so this middleware works with any standards-compliant OIDC provider — Cognito, Auth0, Dex, etc.
///
/// Clients must send the **ID token** (not the access token) in the `Authorization: Bearer` header.
struct OIDCIDTokenPayload: JWTPayload {
  /// Issuer — must match `OIDC_ISSUER_URL` (e.g. Cognito User Pool URL).
  var iss: IssuerClaim

  /// Subject — the unique user identifier from the OIDC provider.
  var sub: SubjectClaim

  /// Audience — must contain `OIDC_CLIENT_ID`.
  var aud: AudienceClaim

  /// Expiration time.
  var exp: ExpirationClaim

  /// Issued-at time (optional but included by Cognito).
  var iat: IssuedAtClaim?

  /// User's email address (standard OIDC profile claim).
  var email: String?

  func verify(using algorithm: some JWTAlgorithm) async throws {
    try exp.verifyNotExpired()
  }
}
