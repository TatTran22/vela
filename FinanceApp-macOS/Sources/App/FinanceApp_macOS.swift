import FinanceData
import SwiftData
import SwiftUI

@main
struct FinanceApp_macOS: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainerSetup.createContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MacContentView()
        }
        .modelContainer(modelContainer)
    }
}
