import Foundation
import SotoS3

/// Manages object storage via AWS S3 in production.
///
/// In non-production environments all operations are no-ops, so local development
/// requires no AWS credentials or bucket configuration.
///
/// All S3 object keys are namespaced by the authenticated user's OIDC subject (`sub`)
/// to enforce per-user data isolation at the storage layer.
actor StorageService {
  private let env: String
  private var s3: S3?
  private var awsClient: AWSClient?
  private let bucketURL: String

  /// Creates a storage service.
  ///
  /// - Parameter env: The current environment. Only `"production"` connects to S3;
  ///   all other values result in a no-op service.
  init(env: String) {
    self.env = env
    self.bucketURL = ""
  }

  /// Creates a production storage service using the given S3 bucket URL.
  ///
  /// - Parameter productionBucketURL: Read from the `PRODUCTION_BUCKET_URL` env var.
  init(productionBucketURL: String) {
    self.env = "production"
    self.bucketURL = productionBucketURL
  }

  /// Builds the S3 object key for a given user and relative path.
  ///
  /// All keys are namespaced under the user's OIDC `sub` so that data stored by
  /// different users cannot collide and access can be scoped by IAM prefix conditions.
  ///
  /// - Parameters:
  ///   - userSub: The `sub` claim from the verified OIDC ID token.
  ///   - path: The relative object path within the user's namespace (e.g. `"documents/file.pdf"`).
  /// - Returns: A namespaced S3 key (e.g. `"user-123/documents/file.pdf"`).
  static func objectKey(userSub: String, path: String) -> String {
    "\(userSub)/\(path)"
  }

  private func connect() async throws {
    guard env == "production" else { return }
    guard s3 == nil else { return }

    let client = AWSClient()
    self.awsClient = client
    self.s3 = S3(client: client)
  }

  /// Returns `true` only in production when the bucket is reachable.
  func healthCheck() async throws -> Bool {
    guard env == "production" else { return false }
    try await connect()
    guard let s3 = s3 else { return false }

    guard let bucketName = URL(string: bucketURL)?.host else { return false }
    let request = S3.HeadBucketRequest(bucket: bucketName)
    do {
      _ = try await s3.headBucket(request)
      return true
    } catch {
      return false
    }
  }

  func shutdown() async throws {
    self.s3 = nil
    if let client = awsClient {
      try await client.shutdown()
      self.awsClient = nil
    }
  }
}

enum StorageError: Error {
  case notConfigured
}
