import FinanceCore
import SwiftUI

/// A searchable picker for selecting a currency from all supported currencies.
///
/// CurrencyPicker provides an intuitive interface for users to select a currency
/// from the full list of supported currency codes. It includes search functionality
/// to quickly filter currencies by code or name.
///
/// Example usage:
/// ```swift
/// @State private var selectedCurrency: CurrencyCode = .VND
///
/// CurrencyPicker(selected: $selectedCurrency)
/// ```
public struct CurrencyPicker: View {
    @Binding var selected: CurrencyCode
    @State private var searchText = ""

    /// Creates a currency picker.
    ///
    /// - Parameter selected: A binding to the currently selected currency code.
    public init(selected: Binding<CurrencyCode>) {
        self._selected = selected
    }

    private var filteredCurrencies: [CurrencyCode] {
        if searchText.isEmpty {
            return CurrencyCode.allCases
        }
        return CurrencyCode.allCases.filter { currency in
            currency.rawValue.localizedCaseInsensitiveContains(searchText) ||
            currency.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    public var body: some View {
        List {
            ForEach(filteredCurrencies, id: \.self) { currency in
                Button {
                    selected = currency
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        // Flag emoji
                        Text(currency.flag)
                            .font(.title3)

                        // Currency code
                        Text(currency.rawValue)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        // Currency name
                        Text(currency.name)
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Currency symbol
                        Text(currency.symbol)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        // Checkmark for selected currency
                        if currency == selected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(currency.name), \(currency.rawValue), symbol \(currency.symbol)")
                .accessibilityHint(currency == selected ? "Currently selected" : "Double tap to select")
            }
        }
        .searchable(text: $searchText, prompt: "Search currencies")
        .navigationTitle("Select Currency")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview("Currency Picker") {
    NavigationStack {
        CurrencyPicker(selected: .constant(.VND))
    }
}

#Preview("With USD Selected") {
    NavigationStack {
        CurrencyPicker(selected: .constant(.USD))
    }
}

#Preview("In Form") {
    struct PreviewWrapper: View {
        @State private var selectedCurrency: CurrencyCode = .VND

        var body: some View {
            NavigationStack {
                Form {
                    Section("Account Details") {
                        HStack {
                            Text("Currency")
                            Spacer()
                            NavigationLink {
                                CurrencyPicker(selected: $selectedCurrency)
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    Text(selectedCurrency.flag)
                                    Text(selectedCurrency.rawValue)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section {
                        HStack {
                            Text("Selected Currency")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(selectedCurrency.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(selectedCurrency.symbol)
                                    .font(.title3)
                            }
                        }
                    }
                }
                .navigationTitle("Account Settings")
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Searchable") {
    struct SearchPreview: View {
        @State private var selectedCurrency: CurrencyCode = .EUR

        var body: some View {
            NavigationStack {
                CurrencyPicker(selected: $selectedCurrency)
            }
        }
    }

    return SearchPreview()
}

#Preview("macOS") {
    NavigationStack {
        CurrencyPicker(selected: .constant(.GBP))
    }
    .frame(width: 400, height: 600)
}
