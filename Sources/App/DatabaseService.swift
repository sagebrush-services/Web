import Foundation
import PostgresNIO
import SotoSecretsManager

actor DatabaseService {
  private var pool: PostgresClient?
  private var awsClient: AWSClient?
  private let secretArn: String

  init(secretArn: String) {
    self.secretArn = secretArn
  }

  func connect() async throws {
    guard pool == nil else { return }

    guard !secretArn.isEmpty else {
      throw DatabaseError.notConfigured
    }

    let client = AWSClient()
    self.awsClient = client
    let secretsManager = SecretsManager(client: client)

    let response = try await secretsManager.getSecretValue(
      .init(secretId: secretArn)
    )

    guard let secretString = response.secretString,
      let secretData = secretString.data(using: .utf8),
      let secret = try? JSONDecoder().decode(DatabaseSecret.self, from: secretData)
    else {
      throw DatabaseError.invalidSecret
    }

    let config = PostgresClient.Configuration(
      host: secret.host,
      port: secret.port,
      username: secret.username,
      password: secret.password,
      database: secret.dbname,
      tls: .prefer(.makeClientConfiguration())
    )

    pool = PostgresClient(configuration: config)
  }

  func healthCheck() async throws -> Bool {
    try await connect()
    guard let pool = pool else { return false }

    let rows = try await pool.query("SELECT 1", logger: .init(label: "db-health"))

    var hasRows = false
    for try await _ in rows {
      hasRows = true
      break
    }
    return hasRows
  }

  func shutdown() async throws {
    self.pool = nil

    if let client = awsClient {
      try await client.shutdown()
      self.awsClient = nil
    }
  }
}

struct DatabaseSecret: Codable {
  let username: String
  let password: String
  let host: String
  let port: Int
  let dbname: String
}

enum DatabaseError: Error {
  case invalidSecret
  case notConfigured
}
