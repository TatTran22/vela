import Foundation
import SwiftData

/// Configures the SwiftData model container for the application
public enum ModelContainerSetup: Sendable {
    /// Creates the shared model container with all registered models
    /// - Parameters:
    ///   - inMemory: Use in-memory store (for tests/previews)
    ///   - enableCloudKit: Enable CloudKit sync (requires entitlements and signing)
    public static func createContainer(
        inMemory: Bool = false,
        enableCloudKit: Bool = false
    ) throws -> ModelContainer {
        if !inMemory {
            let appSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            if !FileManager.default.fileExists(atPath: appSupportURL.path) {
                try FileManager.default.createDirectory(
                    at: appSupportURL,
                    withIntermediateDirectories: true
                )
            }
        }

        let schema = Schema([
            AccountEntity.self,
            ExchangeRateEntity.self,
        ])

        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase
        if inMemory || !enableCloudKit {
            cloudKitDatabase = .none
        } else {
            cloudKitDatabase = .private("iCloud.com.vela.financeapp")
        }

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: cloudKitDatabase
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
