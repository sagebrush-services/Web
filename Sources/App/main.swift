import AWSLambdaEvents
import Configuration
import Foundation
import HarnessDatabaseService
import HarnessOIDCMiddleware
import Hummingbird
import HummingbirdLambda
import OpenAPIHummingbird
import OpenAPIRuntime

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let env = config.string(forKey: "env", default: "local")
let smtpFrom = config.string(forKey: "smtp.from", default: "")
let emailService = EmailService(env: env, from: smtpFrom)

let oidcIssuerURL = config.string(forKey: "oidc.issuer.url", default: "")
let oidcClientID = config.string(forKey: "oidc.client.id", default: "")

switch env {
case "production":
  let databaseURL = config.string(forKey: "database.url", default: "")
  let databaseService = try DatabaseService(databaseURL: databaseURL)

  let productionBucketURL = config.string(forKey: "production.bucket.url", default: "")
  let storageService = StorageService(productionBucketURL: productionBucketURL)

  let keyCollection = try await buildJWTKeyCollection(
    env: env,
    issuerURL: oidcIssuerURL,
    clientID: oidcClientID,
    injectedCollection: nil
  )

  let db = try await databaseService.db
  let router = Router(context: AppLambdaRequestContext.self)
  router.middlewares.add(
    OIDCAuthMiddleware(
      keyCollection: keyCollection,
      issuerURL: oidcIssuerURL,
      clientID: oidcClientID
    )
  )
  router.middlewares.add(AuthorizationMiddleware(db: db))
  try APIHandler(
    databaseService: databaseService,
    emailService: emailService,
    storageService: storageService
  ).registerHandlers(on: router)
  let lambda = APIGatewayV2LambdaFunction(router: router)
  try await lambda.runService()

default:
  let databaseService = DatabaseService()
  try await databaseService.migrate()

  let storageService = StorageService(env: env)
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
