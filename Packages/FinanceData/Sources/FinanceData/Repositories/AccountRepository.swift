import FinanceCore
import Foundation
import SwiftData

/// SwiftData-backed repository for Account entities
public final class AccountRepository: @unchecked Sendable {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
}
