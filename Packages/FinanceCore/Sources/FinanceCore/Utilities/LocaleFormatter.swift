import Foundation

/// Centralized date formatting utility with locale-aware relative dates.
///
/// `LocaleFormatter` provides methods for formatting dates as relative labels
/// ("Today", "Yesterday", "3 days ago") and full date strings, adapting to
/// the current system locale or an explicit override.
public enum LocaleFormatter {
    /// Formats a date as a relative label or full date string.
    ///
    /// - Today → "Today" / "Hôm nay"
    /// - Yesterday → "Yesterday" / "Hôm qua"
    /// - Older → Full date string (e.g., "Monday, Feb 10, 2026" / "Thứ Hai, 10/02/2026")
    ///
    /// - Parameters:
    ///   - date: The date to format.
    ///   - locale: Optional locale override. Defaults to system locale.
    /// - Returns: A formatted date string.
    public static func relativeDate(_ date: Date, locale: Locale? = nil) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return CoreStrings.dateToday
        }

        if calendar.isDateInYesterday(date) {
            return CoreStrings.dateYesterday
        }

        return fullDate(date, locale: locale)
    }

    /// Formats a date as a full weekday + date string.
    ///
    /// Uses the system locale (or override) to determine the format:
    /// - Vietnamese: "Thứ Hai, 10/02/2026"
    /// - English: "Monday, Feb 10, 2026"
    ///
    /// - Parameters:
    ///   - date: The date to format.
    ///   - locale: Optional locale override. Defaults to system locale.
    /// - Returns: A full formatted date string.
    public static func fullDate(_ date: Date, locale: Locale? = nil) -> String {
        let effectiveLocale = locale ?? Locale.current
        let formatter = DateFormatter()
        formatter.locale = effectiveLocale

        if effectiveLocale.language.languageCode?.identifier == "vi" {
            formatter.dateFormat = "EEEE, dd/MM/yyyy"
        } else {
            formatter.dateStyle = .long
        }

        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    /// Formats a month name for the given date.
    ///
    /// - Parameters:
    ///   - date: The date whose month to format.
    ///   - locale: Optional locale override.
    /// - Returns: Month name (e.g., "January" / "Tháng 1").
    public static func monthName(_ date: Date, locale: Locale? = nil) -> String {
        let effectiveLocale = locale ?? Locale.current
        let formatter = DateFormatter()
        formatter.locale = effectiveLocale

        if effectiveLocale.language.languageCode?.identifier == "vi" {
            let month = Calendar.current.component(.month, from: date)
            return "Tháng \(month)"
        } else {
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date)
        }
    }
}
