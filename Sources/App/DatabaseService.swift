import Fluent
import FluentKit
import FluentPostgresDriver
import FluentSQLiteDriver
import HarnessDAL
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

  /// Creates a production database service connecting to Postgres via a connection URL.
  ///
  /// - Parameter databaseURL: A full Postgres connection URL, read from the `DATABASE_URL`
  ///   environment variable (e.g. `postgres://user:password@host:5432/dbname`).
  init(databaseURL: String) throws {
    let databases = Databases(
      threadPool: NIOThreadPool.singleton,
      on: MultiThreadedEventLoopGroup.singleton
    )
    let config = try SQLPostgresConfiguration(url: databaseURL)
    databases.use(DatabaseConfigurationFactory.postgres(configuration: config), as: .psql)
    self.databaseID = .psql
    self.databases = databases
  }

  /// Creates a local SQLite database service.
  ///
  /// - Parameter configuration: The SQLite configuration. Defaults to `.file("db.sqlite")` for
  ///   local development — the file is gitignored. Pass `.memory` in tests to keep each
  ///   test suite isolated and avoid file conflicts from parallel test runs.
  init(configuration: SQLiteConfiguration = .file("db.sqlite")) {
    let databases = Databases(
      threadPool: NIOThreadPool.singleton,
      on: MultiThreadedEventLoopGroup.singleton
    )
    databases.use(DatabaseConfigurationFactory.sqlite(configuration), as: .sqlite)
    self.databaseID = .sqlite
    self.databases = databases
  }

  func migrate() async throws {
    let migrations = Migrations()
    migrations.add(HarnessDALConfiguration.migrations)
    let migrator = Migrator(
      databases: databases,
      migrations: migrations,
      logger: Logger(label: "fluent.migrations"),
      on: MultiThreadedEventLoopGroup.singleton.any()
    )
    try await migrator.setupIfNeeded().get()
    try await migrator.prepareBatch().get()
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
