struct DatabaseCredentials: Codable {
  let username: String
  let password: String
  let host: String
  let port: Int
  let dbname: String
}

enum AppError: Error {
  case invalidDatabaseSecret
}
