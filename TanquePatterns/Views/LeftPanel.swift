import SwiftUI

// MARK: - Panel theme environment keys

private struct PanelLabelColorKey: EnvironmentKey { static let defaultValue: Color = TP.textMut2 }
private struct PanelMutedColorKey: EnvironmentKey { static let defaultValue: Color = TP.textMuted }

extension EnvironmentValues {
    fileprivate(set) var panelLabelColor: Color {
        get { self[PanelLabelColorKey.self] }
        set { self[PanelLabelColorKey.self] = newValue }
    }
    fileprivate(set) var panelMutedColor: Color {
        get { self[PanelMutedColorKey.self] }
        set { self[PanelMutedColorKey.self] = newValue }
    }
}

struct LeftPanel: View {
    @ObservedObject var vm: PatternViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                familySection
                PanelDivider()
                gridSection
                PanelDivider()
                motifSection
                PanelDivider()
                layersSection
                PanelDivider()
                bandsSection
                tileSection
                PanelDivider()
                outputSection
                analyzeSection
                PanelDivider()
                resetButton
            }
            .padding(.horizontal, 12)
            .padding(.top, 13)
        }
        .frame(width: 256)
        .background(vm.panelBg)
        .overlay(alignment: .trailing) {
            Rectangle().fill(TP.border).frame(width: 1)
        }
        .environment(\.panelLabelColor, vm.panelText)
        .environment(\.panelMutedColor, vm.panelMuted)
    }

    // MARK: - Family

    private var familySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Family")
            VStack(spacing: 3) {
                FamilyRow(family: .hexagonal,      name: "Hexagonal",            ref: "pp. 196–197", vm: vm)
                FamilyRow(family: .trihex,         name: "Trihex (6+4+3)",       ref: "pp. 198–199", vm: vm)
                FamilyRow(family: .squareFourfold, name: "Square (8-fold)",       ref: "pp. 200–201", vm: vm)
                FamilyRow(family: .dodecagonal,    name: "Dodecagonal (12-fold)", ref: "",            vm: vm)
            }
            .padding(.bottom, 11)
        }
    }

    // MARK: - Grid

    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Grid")
            PanelSlider(
                label: "Columns",
                value: Binding(
                    get: { Double(vm.state.gridSpec.columns) },
                    set: { vm.state.gridSpec.columns = Int($0) }
                ),
                range: 2...8, step: 1,
                display: { "\(Int($0))" },
                accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
            )
            PanelSlider(
                label: "Rows",
                value: Binding(
                    get: { Double(vm.state.gridSpec.rows) },
                    set: { vm.state.gridSpec.rows = Int($0) }
                ),
                range: 1...8, step: 1,
                display: { "\(Int($0))" },
                accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
            )
            PanelSlider(
                label: "Spacing",
                value: Binding(
                    get: { vm.state.gridSpec.spacing },
                    set: { vm.state.gridSpec.spacing = $0 }
                ),
                range: 52...140, step: 2,
                display: { "\(Int($0))px" },
                accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
            )
            PanelSlider(
                label: "Cell scale",
                value: Binding(
                    get: { vm.state.gridSpec.cellScale },
                    set: { vm.state.gridSpec.cellScale = $0 }
                ),
                range: 0.65...1.00, step: 0.01,
                display: { v in
                    if v <= 0.67 { return String(format: "%.2f gap", v) }
                    if v >= 0.99 { return "1.00 flush" }
                    return String(format: "%.2f", v)
                },
                accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
            )
        }
    }

    // MARK: - Motif

    private var motifSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Motif")
            PanelSlider(
                label: "Star depth",
                value: Binding(
                    get: { vm.state.gridSpec.contactT },
                    set: { vm.state.gridSpec.contactT = $0 }
                ),
                range: 0.10...0.45, step: 0.01,
                display: { "\(Int($0 * 180))°" },
                accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
            )
            PanelSlider(
                label: "Line weight",
                value: Binding(
                    get: { vm.state.displayConfig.lineWeight },
                    set: { vm.state.displayConfig.lineWeight = $0 }
                ),
                range: 0.5...4.0, step: 0.1,
                display: { String(format: "%.1fpx", $0) },
                accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
            )
            PanelDivider()
            SectionLabel("Weave")
            PanelToggle(
                label: "Interlace weave",
                checked: vm.state.weaveMode == .woven,
                dotColor: TP.brass
            ) { vm.state.weaveMode = $0 ? .woven : .flat }
            if vm.state.weaveMode == .woven {
                Text("Arms extend to show\nover/under crossings")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(vm.panelMuted)
                    .lineSpacing(3)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Layers

    private var layersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Layers")
            PanelToggle(
                label: "Guide grid",
                checked: vm.state.layerConfig.showGuideGrid,
                dotColor: Color.white.opacity(0.3)
            ) { vm.state.layerConfig.showGuideGrid = $0 }
            PanelToggle(
                label: "Construction",
                checked: vm.state.layerConfig.showConstruction,
                dotColor: TP.brass.opacity(0.8)
            ) { vm.state.layerConfig.showConstruction = $0 }
            PanelToggle(
                label: "Motif",
                checked: vm.state.layerConfig.showMotif,
                dotColor: vm.panelText.opacity(0.9)
            ) { vm.state.layerConfig.showMotif = $0 }
            PanelToggle(
                label: "Fill",
                checked: vm.state.layerConfig.showFill,
                dotColor: TP.brass
            ) { vm.state.layerConfig.showFill = $0 }
        }
    }

    // MARK: - Bands

    private var bandsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Parallel lines")
            PanelToggle(
                label: "Band strapwork",
                checked: vm.state.bandConfig.showBands,
                dotColor: TP.brass
            ) { vm.state.bandConfig.showBands = $0 }
            if vm.state.bandConfig.showBands {
                VStack(spacing: 0) {
                    PanelSlider(
                        label: "Offset",
                        value: Binding(
                            get: { vm.state.bandConfig.bandOffset },
                            set: { vm.state.bandConfig.bandOffset = $0 }
                        ),
                        range: 1...24, step: 0.5,
                        display: { "\(Int($0))px" },
                        accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
                    )
                    PanelSlider(
                        label: "Count",
                        value: Binding(
                            get: { Double(vm.state.bandConfig.bandCount) },
                            set: { vm.state.bandConfig.bandCount = Int($0) }
                        ),
                        range: 1...4, step: 1,
                        display: { "\(Int($0))" },
                        accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut, value: vm.state.bandConfig.showBands)
    }

    // MARK: - Tile

    @ViewBuilder
    private var tileSection: some View {
        if vm.mode == .tile {
            PanelDivider()
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel("Tile repeat")
                PanelSlider(
                    label: "Gap",
                    value: Binding(
                        get: { vm.state.tileGap },
                        set: { vm.state.tileGap = $0 }
                    ),
                    range: 0...1.6, step: 0.02,
                    display: { String(format: "%.2f", $0) },
                    accentColor: vm.activeTheme.brass, surfaceColor: vm.panelBg
                )
                Text("0 = full overlap · 1 = flush · 1+ = spaced")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(vm.panelMuted)
                    .lineSpacing(3)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Output stats

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Output")
            let counts = vm.cellCounts
            if vm.state.gridSpec.family == .trihex {
                StatRow(label: "Hex cells",  value: "\(counts.hex)")
                StatRow(label: "Sq cells",   value: "\(counts.square)")
                StatRow(label: "Tri cells",  value: "\(counts.triangle)")
            } else {
                StatRow(label: "Cells", value: "\(counts.total)")
            }
            let armCount = vm.resolvedCells.reduce(0) { $0 + $1.motifArms.count }
            StatRow(label: "Motif arms", value: "\(armCount)")
            if let rect = vm.renderOutput?.boundingRect, rect != .null {
                StatRow(label: "Canvas",
                        value: "\(Int(rect.width)) × \(Int(rect.height))px")
            }
        }
    }

    // MARK: - Analyze inspector

    @ViewBuilder
    private var analyzeSection: some View {
        if vm.mode == .analyze {
            PanelDivider()
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel("Analyze")
                if let sel = vm.selectedCellIndex, sel < vm.resolvedCells.count {
                    let rc = vm.resolvedCells[sel]
                    let cell = rc.cell
                    let edgeLen = cell.vertices.count >= 2
                        ? vec2Distance(cell.vertices[0], cell.vertices[1])
                        : 0.0
                    StatRow(label: "type",   value: cell.type.rawValue)
                    StatRow(label: "recipe", value: recipeName(for: cell.type,
                                                               family: vm.state.gridSpec.family))
                    StatRow(label: "arms",   value: rc.motifArms.isEmpty ? "—"
                                                    : "\(rc.motifArms.count)")
                    StatRow(label: "edge",   value: String(format: "%.1fpx", edgeLen))
                    StatRow(label: "center", value: String(format: "%.0f, %.0f",
                                                           cell.center.x, cell.center.y))
                } else {
                    Text("Tap any cell\nto inspect")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(vm.panelMuted)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func recipeName(for type: CellType, family: GridFamily) -> String {
        switch type {
        case .hexagon:  return family == .dodecagonal ? "DodecaStar" : "HexStar"
        case .square:   return family == .trihex ? "SquareCross" : "HexStar"
        case .triangle: return "—"
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button(action: {
            vm.state = .default
        }) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10))
                Text("Reset to defaults")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
            }
            .foregroundColor(TP.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(vm.panelBg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(TP.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 16)
    }
}

// MARK: - FamilyRow

private struct FamilyRow: View {
    let family: GridFamily
    let name: String
    let ref: String
    @ObservedObject var vm: PatternViewModel

    var isSelected: Bool { vm.state.gridSpec.family == family }

    var body: some View {
        Button(action: { vm.state.gridSpec.family = family }) {
            HStack {
                Text(name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .monospaced))
                    .foregroundColor(isSelected ? TP.brass : vm.panelText)
                Spacer()
                if !ref.isEmpty {
                    Text(ref)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(vm.panelMuted)
                        .opacity(0.55)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? TP.brass.opacity(0.08) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? TP.brass : TP.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sub-views

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    @Environment(\.panelMutedColor) private var mutedColor

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .regular, design: .monospaced))
            .tracking(8)
            .foregroundColor(mutedColor)
            .padding(.bottom, 7)
            .padding(.top, 2)
    }
}

struct PanelDivider: View {
    var body: some View {
        Rectangle().fill(TP.border).frame(height: 1).padding(.vertical, 10)
    }
}

struct PanelToggle: View {
    let label: String
    let checked: Bool
    let dotColor: Color
    let onChange: (Bool) -> Void

    @Environment(\.panelLabelColor) private var labelColor
    @Environment(\.panelMutedColor) private var mutedColor

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(dotColor.opacity(checked ? 1.0 : 0.18))
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(checked ? labelColor : mutedColor)
            Spacer()
            ZStack(alignment: checked ? .trailing : .leading) {
                Capsule().fill(checked ? dotColor : TP.bgSurf3)
                    .frame(width: 28, height: 15)
                Circle().fill(Color.white).frame(width: 11, height: 11)
                    .padding(.horizontal, 2)
            }
            .animation(.easeInOut(duration: 0.15), value: checked)
        }
        .contentShape(Rectangle())
        .onTapGesture { onChange(!checked) }
        .padding(.bottom, 7)
    }
}

struct PanelSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let display: (Double) -> String
    var accentColor: Color = TP.brass
    var surfaceColor: Color = TP.bgSurf3

    @Environment(\.panelLabelColor) private var labelColor

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(labelColor)
                Spacer()
                Text(display(value))
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            HStack(spacing: 5) {
                StepButton(label: "–", surfaceColor: surfaceColor,
                           enabled: value > range.lowerBound) {
                    value = max(range.lowerBound, value - step)
                }
                Slider(value: $value, in: range, step: step)
                    .tint(accentColor)
                StepButton(label: "+", surfaceColor: surfaceColor,
                           enabled: value < range.upperBound) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(.bottom, 11)
    }
}

private struct StepButton: View {
    let label: String
    var surfaceColor: Color = TP.bgSurf3
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(TP.textMut2)
                .frame(width: 18, height: 18)
                .background(surfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(TP.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1.0 : 0.35)
        .disabled(!enabled)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    @Environment(\.panelLabelColor) private var labelColor
    @Environment(\.panelMutedColor) private var mutedColor

    var body: some View {
        HStack {
            Text(label).font(.system(size: 10, design: .monospaced)).foregroundColor(mutedColor)
            Spacer()
            Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(labelColor)
        }
        .padding(.bottom, 4)
    }
}
