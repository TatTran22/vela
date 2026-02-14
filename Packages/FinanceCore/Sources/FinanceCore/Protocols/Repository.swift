import Foundation

/// Base repository protocol for CRUD operations
public protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Sendable

    func fetchAll() async throws -> [Entity]
    func fetch(by id: Entity.ID) async throws -> Entity?
    func save(_ entity: Entity) async throws
    func delete(by id: Entity.ID) async throws
}
