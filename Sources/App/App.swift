import Foundation
import Hummingbird
import HummingbirdLambda
import OpenAPIHummingbird
import OpenAPIRuntime

@main
struct App: APIGatewayV2LambdaFunction {
  let databaseService: DatabaseService
  let storageService: StorageService

  init(context: LambdaInitializationContext) async throws {
    let secretArn = ProcessInfo.processInfo.environment["DB_SECRET_ARN"] ?? ""
    let bucketName = ProcessInfo.processInfo.environment["S3_BUCKET_NAME"] ?? ""
    self.databaseService = DatabaseService(secretArn: secretArn)
    self.storageService = StorageService(bucketName: bucketName)
  }

  func buildRouter() -> Router<LambdaRequestContext<APIGatewayV2Request>> {
    let router = Router(context: LambdaRequestContext<APIGatewayV2Request>.self)
    let transport = RouterTransport(router: router)
    try! APIHandler(databaseService: databaseService, storageService: storageService)
      .registerHandlers(on: transport)
    return router
  }
}
