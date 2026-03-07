/// Represents an authenticated user extracted from a verified OIDC ID token.
struct AuthenticatedUser: Sendable {
  /// Subject identifier — the unique user ID from the OIDC provider.
  let sub: String

  /// User's email address, if present in the ID token.
  let email: String?
}
