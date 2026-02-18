import Foundation
import OpenAPIRuntime

struct APIHandler: APIProtocol {
  let databaseService: DatabaseService
  let storageService: StorageService

  func getHealth(
    _ input: Operations.getHealth.Input
  ) async throws -> Operations.getHealth.Output {
    let dbConnected = (try? await databaseService.healthCheck()) ?? false
    let storageAvailable = (try? await storageService.healthCheck()) ?? false

    let overallStatus: Components.Schemas.HealthResponse.statusPayload =
      (dbConnected && storageAvailable) ? .healthy : .degraded

    let response = Components.Schemas.HealthResponse(
      status: overallStatus,
      timestamp: Date(),
      database: dbConnected ? .connected : .disconnected,
      storage: storageAvailable ? .available : .unavailable
    )

    return .ok(.init(body: .json(response)))
  }
}
