import Foundation
import Hummingbird
import JWTKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Hummingbird middleware that verifies a standard OIDC ID token on every request.
///
/// Expects an `Authorization: Bearer <id-token>` header. On success, populates
/// `context.authenticatedUser` with the subject and email from the token.
struct OIDCAuthMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
  let keyCollection: JWTKeyCollection
  let issuerURL: String
  let clientID: String

  func handle(
    _ request: Request,
    context: Context,
    next: (Request, Context) async throws -> Response
  ) async throws -> Response {
    guard
      let authHeader = request.headers[.authorization],
      authHeader.hasPrefix("Bearer ")
    else {
      throw HTTPError(.unauthorized)
    }
    let token = String(authHeader.dropFirst("Bearer ".count))
    let payload: OIDCIDTokenPayload
    do {
      payload = try await keyCollection.verify(token, as: OIDCIDTokenPayload.self)
    } catch {
      throw HTTPError(.unauthorized)
    }
    guard payload.iss.value == issuerURL else {
      throw HTTPError(.unauthorized)
    }
    guard payload.aud.value.contains(clientID) else {
      throw HTTPError(.unauthorized)
    }
    var ctx = context
    ctx.authenticatedUser = AuthenticatedUser(
      sub: payload.sub.value,
      email: payload.email
    )
    return try await next(request, ctx)
  }
}

/// Builds a `JWTKeyCollection` for OIDC token verification.
///
/// - In **production** (`env == "production"`), fetches the JWKS from the OIDC discovery
///   document at `{issuerURL}/.well-known/openid-configuration`, which is provider-agnostic
///   and works with Cognito, Auth0, Dex, or any standards-compliant OIDC provider.
/// - In **non-production** environments, uses `injectedCollection` directly to avoid
///   network calls during local development and testing.
///
/// - Parameters:
///   - env: The current environment string, read via `ConfigReader`. Only `"production"`
///     triggers the network fetch.
///   - issuerURL: The OIDC issuer URL (e.g. Cognito User Pool URL). Read from
///     `OIDC_ISSUER_URL` env var. Ignored in non-production when a collection is injected.
///   - clientID: The OIDC client/app ID. Read from `OIDC_CLIENT_ID` env var.
///   - injectedCollection: A pre-built key collection to use in non-production environments.
///     Pass `nil` only when `env == "production"`.
func buildJWTKeyCollection(
  env: String,
  issuerURL: String,
  clientID: String,
  injectedCollection: JWTKeyCollection?
) async throws -> JWTKeyCollection {
  guard env == "production" else {
    return injectedCollection ?? JWTKeyCollection()
  }

  // Fetch OIDC discovery document to locate the JWKS URI.
  guard
    let discoveryURL = URL(
      string: "\(issuerURL)/.well-known/openid-configuration")
  else {
    throw OIDCConfigError.invalidIssuerURL
  }
  let (discoveryData, _) = try await URLSession.shared.data(from: discoveryURL)
  let discovery = try JSONDecoder().decode(OIDCDiscoveryDocument.self, from: discoveryData)

  // Fetch the JWKS from the URI in the discovery document.
  guard let jwksURL = URL(string: discovery.jwksURI) else {
    throw OIDCConfigError.invalidJWKSURL
  }
  let (jwksData, _) = try await URLSession.shared.data(from: jwksURL)
  let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)

  let keyCollection = JWTKeyCollection()
  try await keyCollection.add(jwks: jwks)
  return keyCollection
}

/// Minimal OIDC discovery document — only the fields this app needs.
private struct OIDCDiscoveryDocument: Decodable {
  let jwksURI: String

  enum CodingKeys: String, CodingKey {
    case jwksURI = "jwks_uri"
  }
}

enum OIDCConfigError: Error {
  case invalidIssuerURL
  case invalidJWKSURL
}
