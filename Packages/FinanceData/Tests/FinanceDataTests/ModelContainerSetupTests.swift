import Testing

@testable import FinanceData

@Suite("ModelContainerSetup Tests")
struct ModelContainerSetupTests {
    @Test("Create in-memory container")
    func createInMemoryContainer() throws {
        let container = try ModelContainerSetup.createContainer(inMemory: true)
        #expect(container.schema.entities.isEmpty == false)
    }
}
