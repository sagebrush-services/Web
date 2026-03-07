import AWSLambdaEvents
import HarnessDAL
import Hummingbird
import HummingbirdLambda

/// Request context used in non-Lambda (local and staging) environments.
protocol AuthenticatedRequestContext: RequestContext {
  var authenticatedUser: AuthenticatedUser? { get set }
}

protocol AuthorizedRequestContext: AuthenticatedRequestContext {
  var userRole: UserRole? { get set }
}

struct AppRequestContext: RequestContext, AuthorizedRequestContext {
  var coreContext: CoreRequestContextStorage
  var authenticatedUser: AuthenticatedUser?
  var userRole: UserRole?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.authenticatedUser = nil
    self.userRole = nil
  }
}

/// Request context used only in the production Lambda runtime.
///
/// Carries the raw `APIGatewayV2Request` event alongside the standard
/// request context, which is required by `HummingbirdLambda`.
struct AppLambdaRequestContext: LambdaRequestContext, AuthorizedRequestContext {
  typealias Event = APIGatewayV2Request
  var coreContext: CoreRequestContextStorage
  let event: APIGatewayV2Request
  var authenticatedUser: AuthenticatedUser?
  var userRole: UserRole?

  init(source: Source) {
    self.coreContext = .init(source: source)
    self.event = source.event
    self.authenticatedUser = nil
    self.userRole = nil
  }
}
