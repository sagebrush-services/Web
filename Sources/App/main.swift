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
let smtpSecretArn = config.string(forKey: "ses.smtp.secret.arn", default: "")
let smtpFrom = config.string(forKey: "smtp.from", default: "")
let storageService = StorageService(bucketName: bucketName)
let emailService = EmailService(env: env, secretArn: smtpSecretArn, from: smtpFrom)

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

  let poolId = config.string(forKey: "cognito.user.pool.id", default: "")
  let cognitoRegion = config.string(forKey: "cognito.region", default: "us-west-2")
  let rawIssuerOverride = config.string(forKey: "jwt.issuer.override", default: "")
  let issuerOverride: String? = rawIssuerOverride.isEmpty ? nil : rawIssuerOverride
  let keyCollection = try await buildJWTKeyCollection(
    poolId: poolId,
    region: cognitoRegion,
    issuerOverride: issuerOverride
  )

  let db = try await databaseService.db
  let router = Router(context: AppLambdaRequestContext.self)
  router.middlewares.add(CognitoAuthMiddleware(keyCollection: keyCollection))
  router.middlewares.add(AuthorizationMiddleware(db: db))
  try APIHandler(
    databaseService: databaseService,
    emailService: emailService,
    storageService: storageService
  ).registerHandlers(on: router)
  let lambda = APIGatewayV2LambdaFunction(router: router)
  try await lambda.runService()

default:
  let databaseService = try DatabaseService(env: env)
  try await databaseService.migrate()

  let router = Router(context: AppRequestContext.self)
  try APIHandler(
    databaseService: databaseService,
    emailService: emailService,
    storageService: storageService
  ).registerHandlers(on: router)
  let app = Application(
    router: router,
    configuration: .init(address: .hostname("localhost", port: 8080))
  )
  try await app.runService()
}
