import Foundation
import SotoS3

actor StorageService {
  private var s3: S3?
  private var awsClient: AWSClient?
  private let bucketName: String

  init(bucketName: String) {
    self.bucketName = bucketName
  }

  private func connect() async throws {
    guard s3 == nil else { return }

    guard !bucketName.isEmpty else {
      throw StorageError.notConfigured
    }

    let client = AWSClient()
    self.awsClient = client
    self.s3 = S3(client: client)
  }

  func healthCheck() async throws -> Bool {
    try await connect()
    guard let s3 = s3 else { return false }

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
