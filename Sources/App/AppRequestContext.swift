import AWSLambdaEvents
import HarnessDAL
import Hummingbird
import HummingbirdLambda

protocol AuthenticatedRequestContext: RequestContext {
  var cognitoUser: CognitoUser? { get set }
}

protocol AuthorizedRequestContext: AuthenticatedRequestContext {
  var userRole: UserRole? { get set }
}

struct AppRequestContext: RequestContext, AuthorizedRequestContext {
  var coreContext: CoreRequestContextStorage
  var cognitoUser: CognitoUser?
  var userRole: UserRole?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.cognitoUser = nil
    self.userRole = nil
  }
}

struct AppLambdaRequestContext: LambdaRequestContext, AuthorizedRequestContext {
  typealias Event = APIGatewayV2Request
  var coreContext: CoreRequestContextStorage
  let event: APIGatewayV2Request
  var cognitoUser: CognitoUser?
  var userRole: UserRole?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.event = source.event
    self.cognitoUser = nil
    self.userRole = nil
  }
}
