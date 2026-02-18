import AWSLambdaEvents
import Foundation
import Hummingbird
import HummingbirdLambda
import OpenAPIHummingbird
import OpenAPIRuntime

@main
struct App {
  static func main() async throws {
    let secretArn = ProcessInfo.processInfo.environment["DB_SECRET_ARN"] ?? ""
    let bucketName = ProcessInfo.processInfo.environment["S3_BUCKET_NAME"] ?? ""
    let databaseService = DatabaseService(secretArn: secretArn)
    let storageService = StorageService(bucketName: bucketName)

    let router = Router(context: BasicLambdaRequestContext<APIGatewayV2Request>.self)
    let transport = RouterTransport(router: router)
    try APIHandler(databaseService: databaseService, storageService: storageService)
      .registerHandlers(on: transport)

    let lambda = APIGatewayV2LambdaFunction(router: router)
    try await lambda.runService()
  }
}
