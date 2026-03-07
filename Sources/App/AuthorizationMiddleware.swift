import FluentKit
import HarnessDAL
import Hummingbird

struct AuthorizationMiddleware<Context: AuthorizedRequestContext>: RouterMiddleware {
  let db: any Database

  func handle(
    _ request: Request,
    context: Context,
    next: (Request, Context) async throws -> Response
  ) async throws -> Response {
    guard let authenticatedUser = context.authenticatedUser else {
      throw HTTPError(.unauthorized)
    }
    guard
      let user = try await User.query(on: db)
        .filter(\.$sub == authenticatedUser.sub)
        .first()
    else {
      throw HTTPError(.unauthorized)
    }
    var ctx = context
    ctx.userRole = user.role
    return try await next(request, ctx)
  }
}
