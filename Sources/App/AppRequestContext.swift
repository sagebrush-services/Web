import AWSLambdaEvents
import Hummingbird
import HummingbirdLambda

protocol AuthenticatedRequestContext: RequestContext {
  var cognitoUser: CognitoUser? { get set }
}

struct AppRequestContext: RequestContext, AuthenticatedRequestContext {
  var coreContext: CoreRequestContextStorage
  var cognitoUser: CognitoUser?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.cognitoUser = nil
  }
}

struct AppLambdaRequestContext: LambdaRequestContext, AuthenticatedRequestContext {
  typealias Event = APIGatewayV2Request
  var coreContext: CoreRequestContextStorage
  let event: APIGatewayV2Request
  var cognitoUser: CognitoUser?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.event = source.event
    self.cognitoUser = nil
  }
}
