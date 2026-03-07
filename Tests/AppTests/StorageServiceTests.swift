import Testing

@testable import App

@Suite("StorageService")
struct StorageServiceTests {

  @Test("healthCheck returns false in non-production (no-op)")
  func nonProductionHealthCheckReturnsFalse() async throws {
    let service = StorageService(env: "local")
    let result = try await service.healthCheck()
    #expect(result == false)
  }

  @Test("objectKey prefixes with userSub")
  func objectKeyPrefixedWithUserSub() {
    let key = StorageService.objectKey(userSub: "user-123", path: "documents/file.pdf")
    #expect(key == "user-123/documents/file.pdf")
  }
}
