import Foundation

/// Normalizes Vietnamese and accented text for diacritics-insensitive search.
///
/// Vietnamese uses a complex system of tone marks and vowel modifications that
/// make simple string comparison unreliable for search. This normalizer strips
/// all diacritical marks and converts text to lowercase so that, for example,
/// "Ăn uống" and "an uong" compare as equal.
///
/// ## Examples
/// ```swift
/// let normalizer = VietnameseTextNormalizer()
/// normalizer.normalize("Ăn uống")  // "an uong"
/// normalizer.normalize("Café")     // "cafe"
/// normalizer.normalize("Phở bò")   // "pho bo"
/// normalizer.normalize("HELLO")    // "hello"
/// ```
public struct VietnameseTextNormalizer: Sendable {
    /// Creates a new `VietnameseTextNormalizer`.
    public init() {}

    /// Normalizes text by lowercasing and removing all diacritical marks.
    ///
    /// This method uses Foundation's `folding(options:locale:)` with
    /// `.diacriticInsensitive` and `.caseInsensitive` options, which correctly
    /// handles Vietnamese tone marks (e.g., ắ → a, ổ → o, ề → e) as well as
    /// common accented characters from other scripts (e.g., é → e, ü → u).
    ///
    /// The `locale` parameter is passed as `nil` so that the Unicode standard
    /// folding rules apply, which is appropriate for a language-agnostic search index.
    ///
    /// - Parameter text: The input text to normalize.
    /// - Returns: A lowercased string with all diacritical marks removed.
    public func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    }
}
