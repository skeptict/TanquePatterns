import SwiftUI

struct TitleBar: View {
    @ObservedObject var vm: PatternViewModel

    var body: some View {
        HStack(spacing: 0) {
            leftCluster
            Spacer()
            modeTabs
            Spacer()
            rightCluster
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(TP.bgPanel)
        .overlay(alignment: .bottom) {
            Rectangle().fill(TP.border).frame(height: 1)
        }
    }

    // MARK: - Left cluster

    private var leftCluster: some View {
        HStack(spacing: 8) {
            // Add spacer to avoid traffic light buttons
            Spacer()
                .frame(width: 60)
            appIcon
            wordmark
        }
    }

    private var appIcon: some View {
        Group {
            if let img = NSImage(named: "AppIcon") {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 21, height: 21)
                    .clipShape(RoundedRectangle(cornerRadius: 4.6))
            } else {
                RoundedRectangle(cornerRadius: 4.6)
                    .fill(TP.brass)
                    .frame(width: 21, height: 21)
            }
        }
    }

    private var wordmark: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("TANQUE")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .tracking(2.5)
                .foregroundColor(TP.textPrim)
            Text("PATTERNS")
                .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                .tracking(8)
                .foregroundColor(TP.textMuted)
                .opacity(0.8)
        }
    }

    // MARK: - Mode tabs

    private var modeTabs: some View {
        HStack(spacing: 1) {
            ForEach(PatternMode.allCases, id: \.self) { m in
                ModeTab(label: m.tabLabel, isActive: vm.mode == m) {
                    vm.setMode(m)
                }
            }
        }
    }

    // MARK: - Right cluster

    private var rightCluster: some View {
        HStack(spacing: 8) {
            themeSwatches
            if vm.mode == .construct {
                replayButton
            }
            exportButton
        }
    }

    private var themeSwatches: some View {
        HStack(spacing: 4) {
            ForEach(ThemeID.allCases, id: \.self) { themeID in
                let theme = PatternTheme.theme(for: themeID)
                let isActive = vm.state.displayConfig.themeID == themeID
                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.brass)
                    .frame(width: 13, height: 13)
                    .scaleEffect(isActive ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isActive)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(isActive ? Color.white : Color.clear, lineWidth: 1)
                    )
                    .onTapGesture { vm.state.displayConfig.themeID = themeID }
            }
        }
    }

    private var replayButton: some View {
        Button(action: { vm.replayConstruct() }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 9))
                Text("REPLAY")
                    .font(.system(size: 10, design: .monospaced))
            }
            .foregroundColor(TP.brass)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(TP.border2, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var exportButton: some View {
        Button(action: { vm.isExportSheetPresented = true }) {
            Text("EXPORT")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundColor(TP.bgApp)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(TP.brass)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode tab

private struct ModeTab: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10.5, weight: isActive ? .semibold : .regular, design: .monospaced))
                .tracking(5)
                .foregroundColor(isActive ? TP.brass : TP.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? TP.brass.opacity(0.12) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .bottom) {
                    if isActive {
                        Rectangle().fill(TP.brass).frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

extension PatternMode: CaseIterable {
    public static var allCases: [PatternMode] { [.construct, .pattern, .tile, .analyze] }

    var tabLabel: String {
        switch self {
        case .construct: return "CONSTRUCT"
        case .pattern:   return "PATTERN"
        case .tile:      return "TILE"
        case .analyze:   return "ANALYZE"
        }
    }
}
