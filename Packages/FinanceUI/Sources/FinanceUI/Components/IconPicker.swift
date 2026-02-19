import SwiftUI

/// A grid-based icon picker for selecting SF Symbols.
///
/// Displays curated icons organized by category, with a search field
/// for filtering. Used in account edit forms for custom icon selection.
public struct IconPicker: View {
    /// The currently selected icon name
    @Binding public var selectedIcon: String

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    /// Available icon categories with their SF Symbol names
    private static let categories: [(name: String, icons: [String])] = [
        ("Finance", [
            "banknote", "creditcard", "building.columns", "dollarsign.circle",
            "yensign.circle", "sterlingsign.circle", "eurosign.circle",
            "chart.line.uptrend.xyaxis", "chart.bar", "percent",
            "wallet.pass", "giftcard", "cart", "bag",
        ]),
        ("Common", [
            "house", "car", "bus", "airplane", "tram",
            "fork.knife", "cup.and.saucer", "takeoutbag.and.cup.and.straw",
            "fuelpump", "bolt", "drop", "flame",
            "wifi", "phone", "envelope", "globe",
        ]),
        ("Health & Education", [
            "heart", "cross.case", "pills", "stethoscope",
            "book", "graduationcap", "pencil.and.ruler", "backpack",
        ]),
        ("Entertainment", [
            "gamecontroller", "film", "music.note", "headphones",
            "sportscourt", "figure.run", "ticket", "popcorn",
        ]),
        ("Savings & Investment", [
            "chart.pie", "arrow.triangle.2.circlepath", "lock.shield",
            "safebox", "leaf", "star", "crown",
            "doc.text", "folder", "archivebox",
        ]),
    ]

    /// All icons flattened for search
    private var allIcons: [String] {
        Self.categories.flatMap { $0.icons }
    }

    /// Filtered icons based on search text
    private var filteredCategories: [(name: String, icons: [String])] {
        if searchText.isEmpty {
            return Self.categories
        }
        let query = searchText.lowercased()
        return Self.categories.compactMap { category in
            let filtered = category.icons.filter { $0.lowercased().contains(query) }
            return filtered.isEmpty ? nil : (category.name, filtered)
        }
    }

    /// Creates a new icon picker
    /// - Parameter selectedIcon: Binding to the selected icon name
    public init(selectedIcon: Binding<String>) {
        self._selectedIcon = selectedIcon
    }

    private let columns = Array(repeating: GridItem(.adaptive(minimum: 44)), count: 1)

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(filteredCategories, id: \.name) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(category.icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedIcon == icon
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.secondary.opacity(0.1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedIcon == icon ? Color.accentColor : .clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Choose Icon")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search icons")
        #endif
    }
}
