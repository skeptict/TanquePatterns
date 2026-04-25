import SwiftUI
import UniformTypeIdentifiers

struct ExportSheet: View {
    @ObservedObject var vm: PatternViewModel
    @Binding var isPresented: Bool

    @State private var exportScale: Double = 2.0
    @State private var exportFormat: ExportFormat = .png

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Export Pattern")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                Spacer()
                Button("Done") { isPresented = false }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TP.textMuted)
            }

            VStack(alignment: .leading, spacing: 12) {
                SectionLabel("Format")
                HStack(spacing: 8) {
                    ForEach(ExportFormat.allCases, id: \.self) { fmt in
                        Button(fmt.rawValue) {
                            exportFormat = fmt
                        }
                        .font(.system(size: 11, weight: exportFormat == fmt ? .semibold : .regular, design: .monospaced))
                        .foregroundColor(exportFormat == fmt ? TP.brass : TP.textMut2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(exportFormat == fmt ? TP.brass.opacity(0.12) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(exportFormat == fmt ? TP.brass : TP.border, lineWidth: 1)
                        )
                    }
                }
            }

            if exportFormat == .png {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Resolution")
                    Picker("Resolution", selection: $exportScale) {
                        Text("1×").tag(1.0)
                        Text("2× (@2x)").tag(2.0)
                        Text("4× (print)").tag(4.0)
                    }
                    .pickerStyle(.segmented)
                    if let rect = vm.renderOutput?.boundingRect {
                        let scaled = CGSize(width: rect.width * exportScale,
                                           height: rect.height * exportScale)
                        Text("\(Int(scaled.width)) × \(Int(scaled.height)) px")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(TP.textMuted)
                    }
                }
            } else if exportFormat == .pdf {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Preview")
                    if let rect = vm.renderOutput?.boundingRect {
                        Text("\(Int(rect.width)) × \(Int(rect.height)) pt  (vector)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(TP.textMuted)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel("Preview")
                    if let rect = vm.renderOutput?.boundingRect {
                        Text("\(Int(rect.width)) × \(Int(rect.height)) pt  (vector)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(TP.textMuted)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("Config")
                Button("Export Config") { vm.exportConfig() }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TP.textMut2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(TP.border, lineWidth: 1)
                    )
            }

            Spacer()

            formatButton
        }
        .padding(20)
        .frame(width: 320, height: 440)
        .background(TP.bgPanel)
    }

    private var formatButton: some View {
        Button("Export \(exportFormat.rawValue)") {
            export()
        }
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .foregroundColor(TP.bgApp)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(TP.brass)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func export() {
        let utType: UTType
        let ext: String
        switch exportFormat {
        case .png:  utType = .png;  ext = "png"
        case .pdf:  utType = .pdf;  ext = "pdf"
        case .svg:  utType = UTType(filenameExtension: "svg") ?? .data;  ext = "svg"
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [utType]
        panel.nameFieldStringValue = "TanquePattern.\(ext)"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                if self.exportFormat == .svg {
                    vm.exportSVG(to: url)
                } else {
                    vm.exportScale = self.exportScale
                    await vm.export(to: url, format: self.exportFormat, scale: self.exportScale)
                }
                isPresented = false
            }
        }
    }
}
