import FinanceCore
import Foundation
import SwiftData

/// Configures the SwiftData model container for the application.
///
/// Provides factory methods for production, testing, and preview containers.
public enum ModelContainerSetup: Sendable {
    /// Creates the shared model container with all registered models.
    /// - Parameters:
    ///   - inMemory: Use in-memory store (for tests/previews).
    ///   - enableCloudKit: Enable CloudKit sync (requires entitlements and signing).
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
            TransactionEntity.self,
            TagEntity.self,
            CategoryEntity.self,
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

    /// Creates an in-memory container for unit testing.
    ///
    /// Each call returns a fresh, isolated container with no pre-populated data.
    public static func createTestingContainer() throws -> ModelContainer {
        try createContainer(inMemory: true)
    }

    /// Creates an in-memory container pre-populated with sample data for SwiftUI previews.
    ///
    /// Inserts default categories, sample accounts, sample tags, sample transactions,
    /// and sample exchange rates from ``SampleData``.
    @MainActor
    public static func createPreviewContainer() throws -> ModelContainer {
        let container = try createContainer(inMemory: true)
        let context = container.mainContext

        // Insert default categories
        for category in DefaultCategories.all {
            context.insert(CategoryEntity.from(domain: category))
        }

        // Insert sample accounts
        for account in SampleData.accounts {
            context.insert(AccountEntity.from(domain: account))
        }

        // Insert sample tags
        for tag in SampleData.tags {
            context.insert(TagEntity.from(domain: tag))
        }

        // Insert sample transactions
        for transaction in SampleData.transactions {
            context.insert(TransactionEntity.from(domain: transaction))
        }

        // Insert sample exchange rates
        for rate in SampleData.exchangeRates {
            context.insert(ExchangeRateEntity.from(domain: rate))
        }

        try context.save()
        return container
    }
}
