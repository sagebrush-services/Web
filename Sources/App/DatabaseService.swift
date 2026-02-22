import Fluent
import FluentKit
import FluentPostgresDriver
import FluentSQLiteDriver
import Logging
import NIOCore
import NIOPosix

actor DatabaseService {
  private let databases: Databases
  private let databaseID: DatabaseID

  var db: any Database {
    get throws {
      guard
        let database = databases.database(
          databaseID,
          logger: Logger(label: "db"),
          on: MultiThreadedEventLoopGroup.singleton.any()
        )
      else {
        throw DatabaseError.notConfigured
      }
      return database
    }
  }

  init(
    env: String,
    hostname: String = "",
    port: Int = 5432,
    username: String = "",
    password: String = "",
    database: String = ""
  ) throws {
    let databases = Databases(
      threadPool: NIOThreadPool.singleton,
      on: MultiThreadedEventLoopGroup.singleton
    )

    if env == "production" || env == "staging" {
      let config = SQLPostgresConfiguration(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database,
        tls: .disable
      )
      databases.use(
        DatabaseConfigurationFactory.postgres(configuration: config),
        as: .psql
      )
      self.databaseID = .psql
    } else {
      databases.use(DatabaseConfigurationFactory.sqlite(.memory), as: .sqlite)
      self.databaseID = .sqlite
    }

    self.databases = databases
  }

  func healthCheck() async throws -> Bool {
    try await (try db).transaction { _ in }
    return true
  }

  func shutdown() {
    databases.shutdown()
  }
}

enum DatabaseError: Error {
  case notConfigured
}
