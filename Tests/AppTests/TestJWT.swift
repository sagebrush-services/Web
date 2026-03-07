import Foundation
import HarnessOIDCMiddleware
import JWTKit

@testable import App

/// Test issuer URL used in place of a real OIDC provider during testing.
let testIssuerURL = "https://test.example.com"

/// Test client ID used in place of a real Cognito App Client ID during testing.
let testClientID = "test-client-id"

private let testRSAPrivateKeyPEM = """
  -----BEGIN PRIVATE KEY-----
  MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCkRVT2KwE+hdEg
  ADwdeiFUFrW7tc247+BcNVq0rHXkleu3W4um7HAC1nP7ce6y24tuVfp6IuOn57Tz
  scFBtm6Ah1s3VZF6+EveikYmuPLwA42p9C1YTOfTOZs5pu1N0jOyGFpsAVzvgQtw
  Jn4PsYXhOw6rdZ+Z7CLNuLUSiQ+3rzMAz26R1isZVZ63d3iylLtBCGhUQGMmQkoV
  P7fGrLGn7pnC/SFwtua7ydMPUJVKUR0CVR4I7lQsqbouH8Hv59WT5CK5CZN1A5BG
  yrzW6ilKr7F3Uc3iJJwNV/eHWkcIJP6GLOFwBgZmpurtSKP3vyVtt54kByD9ayqp
  +eBwyk1tAgMBAAECgf94S3qR990ekbL8gAJYosvjbesvP6hJIFGWB5p0HfVGjeyX
  d67cBt+ljrFgj0qnGUw+JiGwXlTQ678uAaN1P32sZXLubPdYjl2XfAUukmAJ+he0
  qO4xjlw2Bvl4Alx53O1JyZrIMb7c8GboX6ItY2mI/xDdM3LpVBJGspMUWh1zvyL4
  DWXswUDXVPZ+TgUPKKBT5zi1dO0dK2xSN9VMM9XF0/HiQsVMfb45YMexI7BtHYuT
  3k8g/YZDjxGvoO+LK382DO+yz5nMGsCg7t0NvZLaj3QYFJyOkezADlZMi6e239p7
  279d7ZeFDEKsEV1BSrfGHTx4WjKZKTv56udyEgECgYEA5t2iRQbStq01OxBr1LkA
  7HHR7us/ntEq3TENKfSvRb/mO+gW7EvG775FzAXaeqDlKegFrL6WZcXNhcw3jw8W
  dDzGMOlKnN9AtHt63RmZyWbjO/EpBGZc3BhtInK9IMfLLblc4hFcTddVtlbqgOdg
  bZW1omA5xK8p8uSUHTPQDIECgYEAtieoXRA5/n4fsWfx9VSVmlWtz+OeYjKUuVWg
  T1hTwHGHlmWVOnwirIPRDgKVO3c+XP2NDACtTz/eUgJ9j1bp/CvL5ARNnaLvfgQh
  ansvEOu6h0Qf85ZxEAGilH7ODOo9piO3qf8dsCgbm04wI/0USultSR/bEW28GtOm
  G1eZuu0CgYEAloC+HInKLFTWct7NrSu+MmYxGbQ7EWoCq5gioMtmx+3GRh+TchAk
  bH56OftG5tKlEqCzsl285jQBO8xaG+UWGkjUW2Z6wbG5GO+2tRTPcMCmOpmIx9mD
  h+hUnTR3nzsgdXp11trCdex/cBNRZR9xeX8zndtlTZdznWjuNetlIgECgYEAs0lb
  XKYQ/t0y4pGVxEvJqAt2tWyrQqnYWobd79rXLE5SDwTTGap/El/3zxtZuRsIBc0G
  G+86pgsODpgm74OzcCHHYBmgL2zk3prALScrzzLF+EdkT4QeqouBczlQI8QWg8Ua
  DDdvCCih633Mwk9hvs38ZAH3xDLG93ykPLs/M40CgYBsxPoNh+D5LO8+iGV3FWGz
  +BEGK1rlTQsArcAPqU6yH3Dhv4mT5rSOq+mTCluVoc/ITczSc48RowUsarG9ESqj
  3f0zMGkbMYX9m3oKm849QF/xFtKi5vRJ9F+ojdxVZFp5yfU7xaO0BZ3kNqkSbKYU
  uZvld6Gs5UzKtdPZY22LoQ==
  -----END PRIVATE KEY-----
  """

/// Helpers for generating signed OIDC ID tokens in tests.
///
/// Uses a local RSA key pair so tests run offline without hitting a real
/// OIDC discovery endpoint. Pass the key collection from `keyCollection()`
/// into `buildJWTKeyCollection(env:issuerURL:clientID:injectedCollection:)`
/// to wire the middleware without any network calls.
struct TestJWT {
  static let rsaKey = try! Insecure.RSA.PrivateKey(pem: testRSAPrivateKeyPEM)

  /// Signs a standard OIDC ID token with test claims.
  static func token(
    sub: String = "test-sub-\(UUID())",
    email: String = "test@example.com"
  ) async throws -> String {
    let payload = OIDCIDTokenPayload(
      iss: IssuerClaim(value: testIssuerURL),
      sub: SubjectClaim(value: sub),
      aud: AudienceClaim(value: [testClientID]),
      exp: ExpirationClaim(value: Date().addingTimeInterval(3600)),
      iat: IssuedAtClaim(value: Date()),
      email: email
    )
    let keyCollection = JWTKeyCollection()
    await keyCollection.add(rsa: rsaKey, digestAlgorithm: .sha256)
    return try await keyCollection.sign(payload)
  }

  /// Returns a JWTKeyCollection backed by the test RSA public key.
  /// Inject this into `buildJWTKeyCollection` to avoid OIDC discovery fetches.
  static func keyCollection() async -> JWTKeyCollection {
    let collection = JWTKeyCollection()
    await collection.add(rsa: rsaKey.publicKey, digestAlgorithm: .sha256)
    return collection
  }
}
