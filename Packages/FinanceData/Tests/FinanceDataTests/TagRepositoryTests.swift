import Testing
import Foundation
import SwiftData

@testable import FinanceCore
@testable import FinanceData

// Disambiguate from Testing.Tag (which also defines a Tag type in Swift Testing 6+)
private typealias AppTag = FinanceCore.Tag

// MARK: - T26: TagRepository Tests

@Suite("TagRepository Tests")
struct TagRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainerSetup.createContainer(inMemory: true)
    }

    private func makeTag(name: String = "Test Tag", color: String? = nil) -> AppTag {
        AppTag(name: name, color: color)
    }

    // MARK: - fetchAll

    @Test("fetchAll returns empty array for empty repository")
    func testFetchAllEmpty() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tags = try await repo.fetchAll()
        #expect(tags.isEmpty)
    }

    @Test("Save a tag and fetchAll returns it")
    func testSaveAndFetchAll() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tag = makeTag(name: "Business Trip", color: "#FF3B30")
        try await repo.save(tag)

        let tags = try await repo.fetchAll()
        #expect(tags.count == 1)
        #expect(tags.first?.name == "Business Trip")
        #expect(tags.first?.color == "#FF3B30")
    }

    @Test("Save multiple tags and fetchAll returns all of them")
    func testSaveMultipleTagsAndFetchAll() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tag1 = makeTag(name: "Work")
        let tag2 = makeTag(name: "Personal")
        let tag3 = makeTag(name: "Vacation")

        try await repo.save(tag1)
        try await repo.save(tag2)
        try await repo.save(tag3)

        let tags = try await repo.fetchAll()
        #expect(tags.count == 3)
    }

    @Test("fetchAll returns tags ordered alphabetically by name")
    func testFetchAllOrderedAlphabetically() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tagC = makeTag(name: "Charlie")
        let tagA = makeTag(name: "Alpha")
        let tagB = makeTag(name: "Bravo")

        try await repo.save(tagC)
        try await repo.save(tagA)
        try await repo.save(tagB)

        let tags = try await repo.fetchAll()

        #expect(tags.count == 3)
        #expect(tags[0].name == "Alpha")
        #expect(tags[1].name == "Bravo")
        #expect(tags[2].name == "Charlie")
    }

    // MARK: - Save (Upsert)

    @Test("Save upserts: updating an existing tag changes its properties")
    func testSaveUpserts() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        var tag = makeTag(name: "Original", color: "#000000")
        try await repo.save(tag)

        tag.name = "Updated"
        tag.color = "#FFFFFF"
        try await repo.save(tag)

        let tags = try await repo.fetchAll()
        #expect(tags.count == 1)
        #expect(tags.first?.name == "Updated")
        #expect(tags.first?.color == "#FFFFFF")
    }

    @Test("Save tag without color persists nil color")
    func testSaveTagWithoutColor() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        // Construct directly using AppTag to avoid nil ambiguity with the helper
        let tag = AppTag(name: "No Color", color: nil)
        try await repo.save(tag)

        let tags = try await repo.fetchAll()
        #expect(tags.first?.color == nil)
    }

    // MARK: - Delete (Hard Delete)

    @Test("Delete removes tag from repository")
    func testDeleteRemovesTag() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tag = makeTag(name: "To Delete")
        try await repo.save(tag)

        let before = try await repo.fetchAll()
        #expect(before.count == 1)

        try await repo.delete(by: tag.id)

        let after = try await repo.fetchAll()
        #expect(after.isEmpty)
    }

    @Test("Delete one tag does not affect other tags")
    func testDeleteOneTagLeavesOthers() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tag1 = makeTag(name: "Keep Me")
        let tag2 = makeTag(name: "Delete Me")

        try await repo.save(tag1)
        try await repo.save(tag2)

        try await repo.delete(by: tag2.id)

        let remaining = try await repo.fetchAll()
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "Keep Me")
    }

    @Test("Delete non-existent tag is a no-op (does not throw)")
    func testDeleteNonExistentIsNoOp() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let fakeID = UUID()
        // TagRepository.delete(by:) uses hard delete and returns without throwing
        // if the record does not exist — unlike TransactionRepository which throws.
        try await repo.delete(by: fakeID)

        let tags = try await repo.fetchAll()
        #expect(tags.isEmpty)
    }

    @Test("Delete is a hard delete: record is permanently removed")
    func testDeleteIsHardDelete() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let tag = makeTag(name: "Hard Delete Target")
        try await repo.save(tag)
        try await repo.delete(by: tag.id)

        // After hard delete, there should be no trace of the record
        let all = try await repo.fetchAll()
        #expect(all.allSatisfy { $0.id != tag.id })
    }

    // MARK: - Round-Trip Data Integrity

    @Test("Tag properties survive a save-and-fetch round-trip")
    func testRoundTrip() async throws {
        let container = try makeContainer()
        let repo = TagRepository(modelContainer: container)

        let knownID = UUID()
        let tag = AppTag(id: knownID, name: "Road Trip", color: "#34C759")
        try await repo.save(tag)

        let fetched = try await repo.fetchAll()

        #expect(fetched.count == 1)
        #expect(fetched.first?.id == knownID)
        #expect(fetched.first?.name == "Road Trip")
        #expect(fetched.first?.color == "#34C759")
    }
}
