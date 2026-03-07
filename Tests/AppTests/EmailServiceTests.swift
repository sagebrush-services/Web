import Testing

@testable import App

@Suite("EmailService")
struct EmailServiceTests {

  @Test("sendEmail logs and skips sending in non-production environments")
  func nonProductionSkipsEmail() async throws {
    let service = EmailService(env: "local", from: "sender@example.com")
    // Should complete without throwing — no network call, just logs
    try await service.sendEmail(
      to: "recipient@example.com",
      subject: "Test",
      body: "Hello"
    )
  }
}
