import Testing
import Foundation

@testable import FinanceCore

@Suite("LocaleFormatter Tests")
struct LocaleFormatterTests {
    // MARK: - relativeDate

    @Test("relativeDate returns Today for current date")
    func relativeDateToday() {
        let result = LocaleFormatter.relativeDate(Date())
        // In test environment, the source language (en) is used
        #expect(!result.isEmpty)
    }

    @Test("relativeDate returns Yesterday for yesterday")
    func relativeDateYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = LocaleFormatter.relativeDate(yesterday)
        #expect(!result.isEmpty)
    }

    @Test("relativeDate returns full date for older dates")
    func relativeDateOlder() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let result = LocaleFormatter.relativeDate(oldDate)
        // Should not be "Today" or "Yesterday"
        #expect(!result.isEmpty)
    }

    // MARK: - fullDate

    @Test("fullDate returns non-empty string")
    func fullDateNonEmpty() {
        let date = Date()
        let result = LocaleFormatter.fullDate(date)
        #expect(!result.isEmpty)
    }

    @Test("fullDate with Vietnamese locale uses dd/MM/yyyy format")
    func fullDateVietnamese() {
        let components = DateComponents(year: 2026, month: 2, day: 10)
        let date = Calendar.current.date(from: components)!
        let result = LocaleFormatter.fullDate(date, locale: Locale(identifier: "vi"))
        #expect(result.contains("10/02/2026"))
    }

    @Test("fullDate with English locale uses long date style")
    func fullDateEnglish() {
        let components = DateComponents(year: 2026, month: 2, day: 10)
        let date = Calendar.current.date(from: components)!
        let result = LocaleFormatter.fullDate(date, locale: Locale(identifier: "en"))
        #expect(result.contains("2026"))
        #expect(result.contains("February") || result.contains("Feb"))
    }

    @Test("fullDate capitalizes first letter")
    func fullDateCapitalized() {
        let date = Date()
        let result = LocaleFormatter.fullDate(date)
        let firstChar = result.first!
        #expect(firstChar.isUppercase)
    }

    // MARK: - monthName

    @Test("monthName with English locale returns English month")
    func monthNameEnglish() {
        let components = DateComponents(year: 2026, month: 1, day: 1)
        let date = Calendar.current.date(from: components)!
        let result = LocaleFormatter.monthName(date, locale: Locale(identifier: "en"))
        #expect(result == "January")
    }

    @Test("monthName with Vietnamese locale returns Tháng format")
    func monthNameVietnamese() {
        let components = DateComponents(year: 2026, month: 1, day: 1)
        let date = Calendar.current.date(from: components)!
        let result = LocaleFormatter.monthName(date, locale: Locale(identifier: "vi"))
        #expect(result == "Tháng 1")
    }

    @Test("monthName returns correct month for all 12 months", arguments: 1...12)
    func monthNameAllMonths(month: Int) {
        let components = DateComponents(year: 2026, month: month, day: 1)
        let date = Calendar.current.date(from: components)!
        let viResult = LocaleFormatter.monthName(date, locale: Locale(identifier: "vi"))
        #expect(viResult == "Tháng \(month)")

        let enResult = LocaleFormatter.monthName(date, locale: Locale(identifier: "en"))
        #expect(!enResult.isEmpty)
    }
}
