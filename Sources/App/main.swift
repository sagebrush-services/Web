import AWSLambdaEvents
import Configuration
import Foundation
import Hummingbird
import HummingbirdLambda
import OpenAPIHummingbird
import OpenAPIRuntime
import SotoSecretsManager

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let env = config.string(forKey: "env", default: "local")
let bucketName = config.string(forKey: "s3.bucket.name", default: "")
let storageService = StorageService(bucketName: bucketName)

switch env {
case "production", "staging":
  let secretArn = config.string(forKey: "db.secret.arn", default: "")
  let awsClient = AWSClient()
  let secretsManager = SecretsManager(client: awsClient)
  let response = try await secretsManager.getSecretValue(.init(secretId: secretArn))
  try await awsClient.shutdown()

  guard
    let secretString = response.secretString,
    let secretData = secretString.data(using: .utf8),
    let creds = try? JSONDecoder().decode(DatabaseCredentials.self, from: secretData)
  else {
    throw AppError.invalidDatabaseSecret
  }

  let databaseService = try DatabaseService(
    env: env,
    hostname: creds.host,
    port: creds.port,
    username: creds.username,
    password: creds.password,
    database: creds.dbname
  )

  let router = Router(context: BasicLambdaRequestContext<APIGatewayV2Request>.self)
  try APIHandler(databaseService: databaseService, storageService: storageService)
    .registerHandlers(on: router)
  let lambda = APIGatewayV2LambdaFunction(router: router)
  try await lambda.runService()

default:
  let databaseService = try DatabaseService(env: env)
  try await databaseService.migrate()

  let router = Router()
  try APIHandler(databaseService: databaseService, storageService: storageService)
    .registerHandlers(on: router)
  let app = Application(
    router: router,
    configuration: .init(address: .hostname("localhost", port: 8080))
  )
  try await app.runService()
}
