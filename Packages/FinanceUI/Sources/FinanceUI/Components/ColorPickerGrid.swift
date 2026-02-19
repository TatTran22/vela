import SwiftUI

/// A grid of preset color swatches for selecting an account color.
///
/// Displays a compact grid of curated colors. The selected color is highlighted
/// with a checkmark overlay and border.
public struct ColorPickerGrid: View {
    /// The currently selected color hex string
    @Binding public var selectedColorHex: String
    
    /// Optional closure called when a color is selected
    public var onSelect: ((String) -> Void)?

    @State private var showingSystemColorPicker = false
    @State private var hoveredHex: String?

    /// Preset color palette with hex values
    private static let presetColors: [(name: String, hex: String)] = [
        ("Green", "#34C759"),
        ("Blue", "#007AFF"),
        ("Indigo", "#5856D6"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Red", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("Teal", "#5AC8FA"),
        ("Cyan", "#32ADE6"),
        ("Mint", "#00C7BE"),
        ("Brown", "#A2845E"),
        ("Gray", "#8E8E93"),
        ("Dark Blue", "#0A2463"),
        ("Forest", "#1B5E20"),
        ("Wine", "#880E4F"),
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 16)
    ]

    /// Creates a new color picker grid
    /// - Parameters:
    ///   - selectedColorHex: Binding to the selected color hex string
    ///   - onSelect: Optional closure called when a color is selected
    public init(selectedColorHex: Binding<String>, onSelect: ((String) -> Void)? = nil) {
        self._selectedColorHex = selectedColorHex
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Self.presetColors, id: \.hex) { preset in
                    colorSwatch(preset: preset)
                }
                
                // System Color Picker Swatch
                systemPickerSwatch
            }
        }
        .sheet(isPresented: $showingSystemColorPicker) {
            NavigationStack {
                ColorPicker("Choose Custom Color", selection: Binding(
                    get: { Color(hex: selectedColorHex) },
                    set: { selectedColorHex = $0.toHex() ?? selectedColorHex }
                ), supportsOpacity: false)
                .padding()
                .navigationTitle("Custom Color")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onSelect?(selectedColorHex)
                            showingSystemColorPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
    }

    @ViewBuilder
    private func colorSwatch(preset: (name: String, hex: String)) -> some View {
        let isSelected = selectedColorHex.uppercased() == preset.hex.uppercased()
        let isHovered = hoveredHex == preset.hex
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedColorHex = preset.hex
            }
            onSelect?(preset.hex)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: preset.hex))
                    .frame(width: 44, height: 44)
                    .shadow(color: Color(hex: preset.hex).opacity(isSelected || isHovered ? 0.3 : 0), radius: 4, x: 0, y: 2)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected ? 1.1 : (isHovered ? 1.05 : 1.0))
            .overlay {
                Circle()
                    .stroke(
                        Color(hex: preset.hex).opacity(isSelected ? 0.5 : (isHovered ? 0.3 : 0)),
                        lineWidth: 2
                    )
                    .padding(-4)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredHex = hovering ? preset.hex : nil
            }
        }
        .accessibilityLabel(preset.name)
        .accessibilityHint("Selects \(preset.name) color")
    }

    @ViewBuilder
    private var systemPickerSwatch: some View {
        let isCustom = !Self.presetColors.contains { $0.hex.uppercased() == selectedColorHex.uppercased() }
        
        Button {
            showingSystemColorPicker = true
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(isCustom ? Color(hex: selectedColorHex) : .secondary)
                
                if isCustom {
                    Circle()
                        .stroke(Color(hex: selectedColorHex).opacity(0.5), lineWidth: 2)
                        .padding(-4)
                }
            }
            .scaleEffect(isCustom ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Custom Color Picker")
        .accessibilityHint("Opens system color picker for a custom color")
    }
}
