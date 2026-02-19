import Testing
import Foundation

@testable import FinanceCore

// MARK: - T25: VietnameseTextNormalizer Tests

/// Standalone test suite for VietnameseTextNormalizer.
///
/// Additional normalizer tests also exist inside TransactionSearchUseCaseTests as
/// integration coverage of the search pipeline. This file is the authoritative
/// unit-level specification for the normalizer itself.
///
/// Note: The type is named with an `Extended` suffix to avoid a redeclaration
/// conflict with the `VietnameseTextNormalizerTests` suite that already exists
/// inside `TransactionSearchUseCaseTests.swift`.
@Suite("VietnameseTextNormalizer Extended Tests")
struct VietnameseTextNormalizerExtendedTests {
    private let normalizer = VietnameseTextNormalizer()

    // MARK: - Vietnamese Diacritics

    @Test("Ăn uống normalizes to an uong")
    func anUong() {
        #expect(normalizer.normalize("Ăn uống") == "an uong")
    }

    @Test("Lowercase an uong passess through unchanged")
    func anUongLowercase() {
        #expect(normalizer.normalize("ăn uống") == "an uong")
    }

    @Test("Đi chuyển normalizes: chuyển loses diacritics, Đ lowercases")
    func diChuyen() {
        // Foundation's .diacriticInsensitive folding strips tone marks from vowels
        // (ể → e) but "Đ" (U+0110 Latin Capital Letter D with Stroke) is not a
        // diacritical mark — it is a distinct base character. The folding only
        // lowercases it to "đ", it does not map it to the ASCII "d".
        let result = normalizer.normalize("Đi chuyển")
        #expect(result == "đi chuyen")
    }

    @Test("Trà sữa normalizes to tra sua")
    func traSua() {
        #expect(normalizer.normalize("Trà sữa") == "tra sua")
    }

    @Test("Phở bò normalizes to pho bo")
    func phoBo() {
        #expect(normalizer.normalize("Phở bò") == "pho bo")
    }

    // MARK: - Vietnamese All-Caps

    @Test("TIỀN LƯƠNG normalizes to tien luong")
    func tienLuong() {
        #expect(normalizer.normalize("TIỀN LƯƠNG") == "tien luong")
    }

    // MARK: - Latin Diacritics

    @Test("Café normalizes to cafe")
    func cafe() {
        #expect(normalizer.normalize("Café") == "cafe")
    }

    @Test("Résumé normalizes to resume")
    func resume() {
        #expect(normalizer.normalize("Résumé") == "resume")
    }

    // MARK: - Case Folding

    @Test("Hello World normalizes to hello world (no diacritics)")
    func helloWorld() {
        #expect(normalizer.normalize("Hello World") == "hello world")
    }

    @Test("All-uppercase ASCII is lowercased")
    func uppercaseAscii() {
        #expect(normalizer.normalize("HELLO") == "hello")
    }

    @Test("All-lowercase ASCII passes through unchanged")
    func lowercaseAscii() {
        #expect(normalizer.normalize("coffee") == "coffee")
    }

    // MARK: - Edge Cases

    @Test("Empty string returns empty string")
    func emptyString() {
        #expect(normalizer.normalize("") == "")
    }

    @Test("Single diacritical character normalizes to its base")
    func singleDiacriticalCharacter() {
        #expect(normalizer.normalize("Ê") == "e")
    }

    @Test("Numbers and punctuation are preserved")
    func numbersAndPunctuation() {
        #expect(normalizer.normalize("100k + 200k") == "100k + 200k")
    }

    @Test("Mixed ASCII and Vietnamese normalizes correctly")
    func mixedAsciiAndVietnamese() {
        #expect(normalizer.normalize("Mua 5 cái bánh") == "mua 5 cai banh")
    }

    @Test("Whitespace-only string returns whitespace-only string")
    func whitespaceOnly() {
        #expect(normalizer.normalize("   ") == "   ")
    }

    // MARK: - Idempotency

    @Test("Normalizing an already-normalized string is a no-op")
    func normalizingAlreadyNormalizedIsNoOp() {
        let first = normalizer.normalize("Ăn uống")
        let second = normalizer.normalize(first)
        #expect(first == second)
    }
}
