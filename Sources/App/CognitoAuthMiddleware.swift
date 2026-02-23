import Foundation
import Hummingbird
import JWTKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct CognitoAuthMiddleware<Context: AuthenticatedRequestContext>: RouterMiddleware {
  let keyCollection: JWTKeyCollection

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
    let payload = try await keyCollection.verify(token, as: CognitoJWTPayload.self)
    var ctx = context
    ctx.cognitoUser = CognitoUser(sub: payload.sub.value, email: payload.email)
    return try await next(request, ctx)
  }
}

func buildJWTKeyCollection(
  poolId: String,
  region: String,
  issuerOverride: String?
) async throws -> JWTKeyCollection {
  let baseURL: String
  if let override = issuerOverride, !override.isEmpty {
    baseURL = override
  } else {
    baseURL = "https://cognito-idp.\(region).amazonaws.com"
  }
  guard let jwksURL = URL(string: "\(baseURL)/\(poolId)/.well-known/jwks.json") else {
    throw CognitoConfigError.invalidJWKSURL
  }
  let (data, _) = try await URLSession.shared.data(from: jwksURL)
  let jwks = try JSONDecoder().decode(JWKS.self, from: data)
  let keyCollection = JWTKeyCollection()
  try await keyCollection.add(jwks: jwks)
  return keyCollection
}

enum CognitoConfigError: Error {
  case invalidJWKSURL
}
