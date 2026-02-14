import Foundation

/// Protocol for account-related business operations
public protocol AccountUseCaseProtocol: Sendable {
    func getAccounts() async throws -> [Account]
    func getAccount(by id: UUID) async throws -> Account?
    func createAccount(_ account: Account) async throws
    func updateAccount(_ account: Account) async throws
    func deleteAccount(by id: UUID) async throws
    func calculateBalance(for accountID: UUID) async throws -> Decimal
}
