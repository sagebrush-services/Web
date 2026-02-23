import Testing

@testable import App

@Suite("EmailService")
struct EmailServiceTests {

  @Test("sendEmail is skipped in local environment")
  func localEnvSkipsEmail() async throws {
    let service = EmailService(env: "local", secretArn: "", from: "")
    try await service.sendEmail(
      to: "recipient@example.com",
      subject: "Test",
      body: "Hello"
    )
  }

  @Test("sendEmail is skipped in test environment")
  func testEnvSkipsEmail() async throws {
    let service = EmailService(env: "test", secretArn: "", from: "")
    try await service.sendEmail(
      to: "recipient@example.com",
      subject: "Test",
      body: "Hello"
    )
  }
}
