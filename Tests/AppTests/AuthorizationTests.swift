import Foundation
import HarnessDAL
import Hummingbird
import HummingbirdTesting
import Testing

@testable import App

@Suite("Authorization")
struct AuthorizationTests {

  private func createTestUser(
    _ dbService: DatabaseService,
    sub: String,
    role: UserRole
  ) async throws {
    let db = try await dbService.db
    let person = Person()
    person.name = sub
    person.email = "\(sub)@example.com"
    try await person.save(on: db)
    let user = User()
    user.$person.id = person.id!
    user.role = role
    user.sub = sub
    try await user.save(on: db)
  }

  private func makeRouter(dbService: DatabaseService) async throws -> Router<AppRequestContext> {
    let keyCollection = await TestJWT.keyCollection()
    let router = Router(context: AppRequestContext.self)
    router.middlewares.add(
      OIDCAuthMiddleware(
        keyCollection: keyCollection,
        issuerURL: testIssuerURL,
        clientID: testClientID
      )
    )
    router.middlewares.add(AuthorizationMiddleware(db: try await dbService.db))
    return router
  }

  // MARK: - OIDCAuthMiddleware

  @Test("Missing Authorization header returns 401")
  func missingAuthHeader() async throws {
    let dbService = DatabaseService(configuration: .memory)
    try await dbService.migrate()
    let router = try await makeRouter(dbService: dbService)
    router.get("/test") { _, _ in "" }
    let app = Application(router: router)
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "/test", method: .get)
      #expect(response.status == .unauthorized)
    }
    await dbService.shutdown()
  }

  @Test("Invalid Bearer token returns 401")
  func invalidBearerToken() async throws {
    let dbService = DatabaseService(configuration: .memory)
    try await dbService.migrate()
    let router = try await makeRouter(dbService: dbService)
    router.get("/test") { _, _ in "" }
    let app = Application(router: router)
    try await app.test(.router) { client in
      let response = try await client.execute(
        uri: "/test",
        method: .get,
        headers: [.authorization: "Bearer not.a.valid.token"]
      )
      #expect(response.status == .unauthorized)
    }
    await dbService.shutdown()
  }

  // MARK: - AuthorizationMiddleware

  @Test("Customer user returns 200 with customer role")
  func customerRole() async throws {
    let dbService = DatabaseService(configuration: .memory)
    try await dbService.migrate()
    let sub = "customer-sub"
    try await createTestUser(dbService, sub: sub, role: .customer)
    let router = try await makeRouter(dbService: dbService)
    router.get("/test") { _, context in context.userRole?.rawValue ?? "unknown" }
    let app = Application(router: router)
    let token = try await TestJWT.token(sub: sub)
    try await app.test(.router) { client in
      let response = try await client.execute(
        uri: "/test",
        method: .get,
        headers: [.authorization: "Bearer \(token)"]
      )
      #expect(response.status == .ok)
      #expect(String(buffer: response.body) == "customer")
    }
    await dbService.shutdown()
  }

  @Test("Staff user returns 200 with staff role")
  func staffRole() async throws {
    let dbService = DatabaseService(configuration: .memory)
    try await dbService.migrate()
    let sub = "staff-sub"
    try await createTestUser(dbService, sub: sub, role: .staff)
    let router = try await makeRouter(dbService: dbService)
    router.get("/test") { _, context in context.userRole?.rawValue ?? "unknown" }
    let app = Application(router: router)
    let token = try await TestJWT.token(sub: sub)
    try await app.test(.router) { client in
      let response = try await client.execute(
        uri: "/test",
        method: .get,
        headers: [.authorization: "Bearer \(token)"]
      )
      #expect(response.status == .ok)
      #expect(String(buffer: response.body) == "staff")
    }
    await dbService.shutdown()
  }

  @Test("Admin user returns 200 with admin role")
  func adminRole() async throws {
    let dbService = DatabaseService(configuration: .memory)
    try await dbService.migrate()
    let sub = "admin-sub"
    try await createTestUser(dbService, sub: sub, role: .admin)
    let router = try await makeRouter(dbService: dbService)
    router.get("/test") { _, context in context.userRole?.rawValue ?? "unknown" }
    let app = Application(router: router)
    let token = try await TestJWT.token(sub: sub)
    try await app.test(.router) { client in
      let response = try await client.execute(
        uri: "/test",
        method: .get,
        headers: [.authorization: "Bearer \(token)"]
      )
      #expect(response.status == .ok)
      #expect(String(buffer: response.body) == "admin")
    }
    await dbService.shutdown()
  }

  @Test("Unknown sub returns 401")
  func unknownSub() async throws {
    let dbService = DatabaseService(configuration: .memory)
    try await dbService.migrate()
    let router = try await makeRouter(dbService: dbService)
    router.get("/test") { _, _ in "" }
    let app = Application(router: router)
    let token = try await TestJWT.token(sub: "unknown-sub")
    try await app.test(.router) { client in
      let response = try await client.execute(
        uri: "/test",
        method: .get,
        headers: [.authorization: "Bearer \(token)"]
      )
      #expect(response.status == .unauthorized)
    }
    await dbService.shutdown()
  }
}
