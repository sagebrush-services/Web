import Foundation
import SotoSES
import SotoSecretsManager

struct EmailCredentials: Codable {
  let username: String
  let password: String
}

enum EmailError: Error {
  case invalidCredentials
}

actor EmailService {
  private let env: String
  private let secretArn: String
  private let from: String

  init(env: String, secretArn: String, from: String) {
    self.env = env
    self.secretArn = secretArn
    self.from = from
  }

  func sendEmail(to recipient: String, subject: String, body: String) async throws {
    guard env != "local", env != "test" else { return }

    let awsClient = AWSClient()
    let secretsManager = SecretsManager(client: awsClient)
    let secretResponse = try await secretsManager.getSecretValue(
      .init(secretId: secretArn)
    )
    try await awsClient.shutdown()

    guard
      let secretString = secretResponse.secretString,
      let secretData = secretString.data(using: .utf8),
      let creds = try? JSONDecoder().decode(EmailCredentials.self, from: secretData)
    else {
      throw EmailError.invalidCredentials
    }

    let sesClient = AWSClient(
      credentialProvider: .static(
        accessKeyId: creds.username,
        secretAccessKey: creds.password
      )
    )
    let ses = SES(client: sesClient)
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
    try await sesClient.shutdown()
    if let error = sendError {
      throw error
    }
  }
}
