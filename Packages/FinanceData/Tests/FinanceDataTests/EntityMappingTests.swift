import Foundation
import SwiftData
import Testing

@testable import FinanceCore
@testable import FinanceData

@Suite("Entity Mapping Round-Trip Tests")
struct EntityMappingTests {
    // MARK: - Account Mapping

    @Suite("AccountEntity Mapping")
    struct AccountMappingTests {
        @Test("Round trip: Account → AccountEntity → Account preserves all fields")
        func accountRoundTrip() {
            let original = Account(
                name: "Vietcombank",
                type: .bank,
                currency: .USD,
                initialBalance: 10_000,
                balance: 8_500,
                iconName: "building.columns",
                colorHex: "#007AFF",
                sortOrder: 3,
                isHidden: true,
                isArchived: false,
                note: "Main checking account",
                eWalletProvider: nil,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                updatedAt: Date(timeIntervalSince1970: 1_700_100_000),
                deletedAt: nil
            )

            let entity = AccountEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.id == original.id)
            #expect(restored.name == original.name)
            #expect(restored.type == original.type)
            #expect(restored.currency == original.currency)
            #expect(restored.initialBalance == original.initialBalance)
            #expect(restored.balance == original.balance)
            #expect(restored.iconName == original.iconName)
            #expect(restored.colorHex == original.colorHex)
            #expect(restored.sortOrder == original.sortOrder)
            #expect(restored.isHidden == original.isHidden)
            #expect(restored.isArchived == original.isArchived)
            #expect(restored.note == original.note)
            #expect(restored.eWalletProvider == original.eWalletProvider)
            #expect(restored.createdAt == original.createdAt)
            #expect(restored.updatedAt == original.updatedAt)
            #expect(restored.deletedAt == original.deletedAt)
        }

        @Test("Round trip preserves eWallet provider")
        func accountEWalletRoundTrip() {
            let original = Account(
                name: "MoMo",
                type: .eWallet,
                eWalletProvider: .momo
            )

            let entity = AccountEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.eWalletProvider == .momo)
        }

        @Test("Round trip preserves soft delete timestamp")
        func accountSoftDeleteRoundTrip() {
            let deleteDate = Date(timeIntervalSince1970: 1_700_200_000)
            var original = Account(name: "Deleted", type: .cash)
            original.deletedAt = deleteDate

            let entity = AccountEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.deletedAt == deleteDate)
        }

        @Test("Update entity from domain model")
        func accountUpdateFromDomain() {
            let original = Account(name: "Original", type: .cash, balance: 100)
            let entity = AccountEntity.from(domain: original)

            var updated = original
            updated.name = "Updated Name"
            updated.balance = 500
            updated.isArchived = true
            entity.update(from: updated)

            let restored = entity.toDomain()
            #expect(restored.id == original.id) // ID unchanged
            #expect(restored.name == "Updated Name")
            #expect(restored.balance == 500)
            #expect(restored.isArchived == true)
        }

        @Test("Nil note maps to nil, not empty string")
        func accountNilNote() {
            let original = Account(name: "No Note", type: .bank, note: nil)
            let entity = AccountEntity.from(domain: original)
            let restored = entity.toDomain()
            #expect(restored.note == nil)
        }
    }

    // MARK: - Transaction Mapping

    @Suite("TransactionEntity Mapping")
    struct TransactionMappingTests {
        @Test("Round trip: Transaction → TransactionEntity → Transaction preserves all fields")
        func transactionRoundTrip() {
            let tagID1 = UUID()
            let tagID2 = UUID()
            let original = Transaction(
                amount: 150_000,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID(),
                toAccountID: nil,
                note: "Lunch with team",
                date: Date(timeIntervalSince1970: 1_700_050_000),
                isRecurring: true,
                tags: [tagID1, tagID2],
                latitude: 10.7769,
                longitude: 106.7009,
                receiptImageData: Data([0x89, 0x50, 0x4E, 0x47]),
                metadata: ["merchant": "Phở 24", "source": "manual"],
                deletedAt: nil,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                updatedAt: Date(timeIntervalSince1970: 1_700_100_000)
            )

            let entity = TransactionEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.id == original.id)
            #expect(restored.amount == original.amount)
            #expect(restored.type == original.type)
            #expect(restored.categoryID == original.categoryID)
            #expect(restored.accountID == original.accountID)
            #expect(restored.toAccountID == original.toAccountID)
            #expect(restored.note == original.note)
            #expect(restored.date == original.date)
            #expect(restored.isRecurring == original.isRecurring)
            #expect(restored.tags == original.tags)
            #expect(restored.latitude == original.latitude)
            #expect(restored.longitude == original.longitude)
            #expect(restored.receiptImageData == original.receiptImageData)
            #expect(restored.metadata == original.metadata)
            #expect(restored.deletedAt == original.deletedAt)
            #expect(restored.createdAt == original.createdAt)
            #expect(restored.updatedAt == original.updatedAt)
        }

        @Test("Round trip preserves transfer with toAccountID")
        func transactionTransferRoundTrip() {
            let toAccountID = UUID()
            let original = Transaction(
                amount: 5_000_000,
                type: .transfer,
                categoryID: UUID(),
                accountID: UUID(),
                toAccountID: toAccountID,
                note: "Transfer to savings"
            )

            let entity = TransactionEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.type == .transfer)
            #expect(restored.toAccountID == toAccountID)
        }

        @Test("Empty tags round-trip to empty array")
        func transactionEmptyTags() {
            let original = Transaction(
                amount: 100,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID(),
                tags: []
            )

            let entity = TransactionEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.tags.isEmpty)
        }

        @Test("Nil metadata round-trips to nil")
        func transactionNilMetadata() {
            let original = Transaction(
                amount: 100,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID(),
                metadata: nil
            )

            let entity = TransactionEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.metadata == nil)
        }

        @Test("Nil receiptImageData round-trips to nil")
        func transactionNilReceipt() {
            let original = Transaction(
                amount: 100,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID(),
                receiptImageData: nil
            )

            let entity = TransactionEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.receiptImageData == nil)
        }

        @Test("Update entity from domain model preserves receipt data")
        func transactionUpdateFromDomain() {
            let original = Transaction(
                amount: 100,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID()
            )
            let entity = TransactionEntity.from(domain: original)

            var updated = original
            updated.amount = 200
            updated.receiptImageData = Data([0xFF, 0xD8])
            updated.note = "Updated note"
            entity.update(from: updated)

            let restored = entity.toDomain()
            #expect(restored.amount == 200)
            #expect(restored.receiptImageData == Data([0xFF, 0xD8]))
            #expect(restored.note == "Updated note")
        }
    }

    // MARK: - Category Mapping

    @Suite("CategoryEntity Mapping")
    struct CategoryMappingTests {
        @Test("Round trip: Category → CategoryEntity → Category preserves all fields")
        func categoryRoundTrip() {
            let parentID = UUID()
            let original = FinanceCore.Category(
                name: "Ăn uống",
                localizedName: "Food & Dining",
                iconName: "fork.knife",
                colorHex: "#FF6B6B",
                type: .expense,
                parentID: parentID,
                sortOrder: 2,
                isDefault: true,
                isArchived: false,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000)
            )

            let entity = CategoryEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.id == original.id)
            #expect(restored.name == original.name)
            #expect(restored.localizedName == original.localizedName)
            #expect(restored.iconName == original.iconName)
            #expect(restored.colorHex == original.colorHex)
            #expect(restored.type == original.type)
            #expect(restored.parentID == original.parentID)
            #expect(restored.sortOrder == original.sortOrder)
            #expect(restored.isDefault == original.isDefault)
            #expect(restored.isArchived == original.isArchived)
            #expect(restored.createdAt == original.createdAt)
        }

        @Test("Top-level category has nil parentID")
        func categoryTopLevel() {
            let original = FinanceCore.Category(
                name: "Lương",
                type: .income,
                parentID: nil
            )

            let entity = CategoryEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.parentID == nil)
        }

        @Test("isArchived round-trips correctly")
        func categoryArchived() {
            let original = FinanceCore.Category(
                name: "Old Category",
                type: .expense,
                isArchived: true
            )

            let entity = CategoryEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.isArchived == true)
        }

        @Test("localizedName defaults to name when empty")
        func categoryLocalizedNameDefault() {
            let category = FinanceCore.Category(
                name: "Ăn uống",
                type: .expense
            )
            #expect(category.localizedName == "Ăn uống")
        }

        @Test("Update entity from domain model")
        func categoryUpdateFromDomain() {
            let original = FinanceCore.Category(
                name: "Original",
                type: .expense
            )
            let entity = CategoryEntity.from(domain: original)

            var updated = original
            updated.name = "Updated"
            updated.localizedName = "Updated EN"
            updated.isArchived = true
            entity.update(from: updated)

            let restored = entity.toDomain()
            #expect(restored.name == "Updated")
            #expect(restored.localizedName == "Updated EN")
            #expect(restored.isArchived == true)
        }
    }

    // MARK: - Tag Mapping

    @Suite("TagEntity Mapping")
    struct TagMappingTests {
        @Test("Round trip: Tag → TagEntity → Tag preserves all fields")
        func tagRoundTrip() {
            let original = Tag(
                name: "Business Trip",
                color: "#FF3B30",
                createdAt: Date(timeIntervalSince1970: 1_700_000_000)
            )

            let entity = TagEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.id == original.id)
            #expect(restored.name == original.name)
            #expect(restored.color == original.color)
            #expect(restored.createdAt == original.createdAt)
        }

        @Test("Nil color round-trips to nil")
        func tagNilColor() {
            let original = Tag(name: "No Color", color: nil)

            let entity = TagEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.color == nil)
        }

        @Test("Update entity from domain model")
        func tagUpdateFromDomain() {
            let original = Tag(name: "Original", color: "#000000")
            let entity = TagEntity.from(domain: original)

            var updated = original
            updated.name = "Updated"
            updated.color = "#FFFFFF"
            entity.update(from: updated)

            let restored = entity.toDomain()
            #expect(restored.name == "Updated")
            #expect(restored.color == "#FFFFFF")
        }
    }

    // MARK: - ExchangeRate Mapping

    @Suite("ExchangeRateEntity Mapping")
    struct ExchangeRateMappingTests {
        @Test("Round trip: ExchangeRate → ExchangeRateEntity → ExchangeRate preserves all fields")
        func exchangeRateRoundTrip() {
            let original = ExchangeRate(
                baseCurrency: .USD,
                targetCurrency: .VND,
                rate: 25_450,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                source: "ECB"
            )

            let entity = ExchangeRateEntity.from(domain: original)
            let restored = entity.toDomain()

            #expect(restored.id == original.id)
            #expect(restored.baseCurrency == original.baseCurrency)
            #expect(restored.targetCurrency == original.targetCurrency)
            #expect(restored.rate == original.rate)
            #expect(restored.date == original.date)
            #expect(restored.source == original.source)
        }

        @Test("Update entity from domain model")
        func exchangeRateUpdateFromDomain() {
            let original = ExchangeRate(
                baseCurrency: .USD,
                targetCurrency: .VND,
                rate: 25_000,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                source: "old"
            )
            let entity = ExchangeRateEntity.from(domain: original)

            var updated = original
            updated.rate = 25_500
            updated.source = "updated"
            entity.update(from: updated)

            let restored = entity.toDomain()
            #expect(restored.rate == 25_500)
            #expect(restored.source == "updated")
        }

        @Test("All currency codes round-trip correctly")
        func allCurrencyCodesRoundTrip() {
            for base in CurrencyCode.allCases {
                for target in CurrencyCode.allCases where target != base {
                    let original = ExchangeRate(
                        baseCurrency: base,
                        targetCurrency: target,
                        rate: 1,
                        date: Date()
                    )
                    let entity = ExchangeRateEntity.from(domain: original)
                    let restored = entity.toDomain()
                    #expect(restored.baseCurrency == base)
                    #expect(restored.targetCurrency == target)
                }
            }
        }
    }
}
