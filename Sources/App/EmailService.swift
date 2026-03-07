import Foundation
import Logging
import SotoSES

private let logger = Logger(label: "email-service")

/// Sends email via AWS SES in production, and logs to stdout in all other environments.
///
/// In production, the Lambda execution role must have `ses:SendEmail` permission.
/// No explicit credentials are needed — `AWSClient()` automatically uses the role.
actor EmailService {
  private let env: String
  private let from: String

  init(env: String, from: String) {
    self.env = env
    self.from = from
  }

  func sendEmail(to recipient: String, subject: String, body: String) async throws {
    guard env == "production" else {
      logger.info(
        "EmailService: skipping send in \(env) — to=\(recipient) subject=\(subject)"
      )
      return
    }

    let awsClient = AWSClient()
    let ses = SES(client: awsClient)
    let request = SES.SendEmailRequest(
      destination: .init(toAddresses: [recipient]),
      message: .init(
        body: .init(text: .init(charset: "UTF-8", data: body)),
        subject: .init(charset: "UTF-8", data: subject)
      ),
      source: from
    )
    var sendError: (any Error)?
    do {
      _ = try await ses.sendEmail(request)
    } catch {
      sendError = error
    }
    try await awsClient.shutdown()
    if let error = sendError {
      throw error
    }
  }
}
