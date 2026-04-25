import SwiftUI
import SwiftData
import Combine

@MainActor
final class PatternViewModel: ObservableObject {
    @Published var state: PatternDocumentState = .default {
        didSet {
            guard !isRestoringDocument else { return }
            recompute()
            scheduleAutosaveIfNeeded()
        }
    }
    @Published var renderOutput: RenderOutput? = nil
    @Published var mode: PatternMode = .pattern
    @Published var resolvedCells: [ResolvedCell] = []
    @Published var animStep: Double = 0
    @Published var selectedCellIndex: Int? = nil
    @Published var isExportSheetPresented = false
    @Published var exportScale: Double = 2.0

    static var sharedThemeID: ThemeID = .dark

    func setTheme(_ themeID: ThemeID) {
        Self.sharedThemeID = themeID
        state.displayConfig.themeID = themeID
    }

    private var saveTask: Task<Void, Never>?
    private var recomputeTask: Task<Void, Never>?
    private var autosaveContext: ModelContext?
    private var document: PatternDocument?
    private var animTimer: Timer?
    private var isRestoringDocument = false

    var cellCounts: (hex: Int, square: Int, triangle: Int, total: Int) {
        let cells = resolvedCells.map(\.cell)
        return (
            hex:      cells.filter { $0.type == .hexagon  }.count,
            square:   cells.filter { $0.type == .square   }.count,
            triangle: cells.filter { $0.type == .triangle }.count,
            total:    cells.count
        )
    }

    var activeTheme: PatternTheme {
        PatternTheme.theme(for: state.displayConfig.themeID)
    }
    var panelBg: Color {
        activeTheme.isPaper ? Color(hex: "#e5ddc8") : TP.bgPanel
    }
    var panelText: Color {
        activeTheme.isPaper ? Color(hex: "#1a140c") : TP.textPrim
    }
    var panelMuted: Color {
        activeTheme.isPaper ? Color(hex: "#7a5e48") : TP.textMuted
    }

    init() {
        recompute()
    }

    deinit {
        animTimer?.invalidate()
    }

    func recompute() {
        recomputeTask?.cancel()
        let currentState = state
        recomputeTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            let spec = currentState.gridSpec.asGridSpec
            let cells = GridGenerator().generate(spec: spec)
            let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
            let output = PatternRenderer().render(
                cells: resolved,
                spec: spec,
                weaveMode: currentState.weaveMode,
                bandOffset: currentState.bandConfig.bandOffset,
                bandCount: currentState.bandConfig.showBands
                    ? currentState.bandConfig.bandCount : 0
            )
            guard !Task.isCancelled else { return }
            self.resolvedCells = resolved.filter { !$0.cell.isBleed }
            self.renderOutput = output
            if self.mode == .construct { self.startConstructAnimation() }
        }
    }

    func attach(document: PatternDocument, context: ModelContext) {
        autosaveContext = context
        self.document = document

        isRestoringDocument = true
        let loadedState = document.loadState()
        mode = loadedState.lastMode
        state = loadedState
        selectedCellIndex = nil
        Self.sharedThemeID = loadedState.displayConfig.themeID
        isRestoringDocument = false

        recompute()
    }

    func setMode(_ newMode: PatternMode) {
        mode = newMode
        animTimer?.invalidate()
        animTimer = nil
        if newMode == .analyze  { selectedCellIndex = nil }
        if newMode == .construct { startConstructAnimation() }
        if state.lastMode != newMode {
            state.lastMode = newMode
        }
    }

    func startConstructAnimation() {
        animTimer?.invalidate()
        animStep = 0
        let startTime = Date()
        let duration: TimeInterval = 3.4
        animTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { timer.invalidate(); return }
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(1.0, elapsed / duration)
                self.animStep = progress
                if progress >= 1.0 {
                    timer.invalidate()
                    self.animTimer = nil
                }
            }
        }
        RunLoop.main.add(animTimer!, forMode: .common)
    }

    func replayConstruct() {
        startConstructAnimation()
    }

    func selectCell(_ index: Int?) {
        guard mode == .analyze else { return }
        selectedCellIndex = (selectedCellIndex == index) ? nil : index
    }

    func scheduleAutosave(context: ModelContext) {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self.persist(context: context)
        }
    }

    private func scheduleAutosaveIfNeeded() {
        guard let autosaveContext, document != nil else { return }
        scheduleAutosave(context: autosaveContext)
    }

    private func persist(context: ModelContext) {
        document?.saveState(state)
        try? context.save()
    }

    func exportConfig() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "pattern.tanquepat"
        panel.canCreateDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? data.write(to: url)
        }
    }

    func importConfig() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard let self,
                  response == .OK,
                  let url = panel.url,
                  let data = try? Data(contentsOf: url),
                  let loaded = try? JSONDecoder().decode(PatternDocumentState.self, from: data) else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.state = loaded
            }
        }
    }

    func exportSVG(to url: URL) {
        guard let output = renderOutput else { return }
        let theme = activeTheme
        let svgSpec = SVGExportSpec(
            includeConstructionLines: state.layerConfig.showConstruction,
            includeGridLines: state.layerConfig.showGuideGrid,
            includeBands: state.bandConfig.showBands,
            backgroundColor: theme.backgroundHex,
            motifColor: theme.motifHex,
            constructionColor: theme.constructionHex,
            gridColor: theme.isPaper ? "#000000" : "#ffffff",
            motifOpacity: 0.90,
            lineWeight: state.displayConfig.lineWeight
        )
        let svgString = SVGExporter().export(output: output, spec: svgSpec)
        try? svgString.data(using: .utf8)?.write(to: url)
    }

    func export(to url: URL, format: ExportFormat, scale: Double) async {
        guard let output = renderOutput else { return }
        let exportBounds = exportBounds(for: output, scale: scale)
        let exportView = exportView(output: output, exportBounds: exportBounds, scale: scale)
        let scaledSize = CGSize(width: exportBounds.width, height: exportBounds.height)
        let renderer = ImageRenderer(content: exportView)
        renderer.scale = 1.0  // We already scaled the view frame

        switch format {
        case .png:
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else { return }
            try? png.write(to: url)
        case .pdf:
            let hostingView = NSHostingView(rootView: exportView)
            hostingView.frame = CGRect(origin: .zero, size: scaledSize)
            hostingView.layoutSubtreeIfNeeded()
            let pdfData = hostingView.dataWithPDF(inside: hostingView.bounds)
            try? pdfData.write(to: url)
        case .svg:
            break  // routed through exportSVG(to:) in ExportSheet
        }
    }

    private func exportView(output: RenderOutput, exportBounds: CGRect, scale: Double) -> some View {
        return Group {
            if mode == .tile {
                TileRenderExport(output: output, exportBounds: exportBounds, vm: self, exportScale: scale)
            } else {
                PatternRenderExport(output: output, exportBounds: exportBounds, vm: self, exportScale: scale)
            }
        }
        .frame(width: exportBounds.width, height: exportBounds.height)
    }

    private func exportBounds(for output: RenderOutput, scale: Double) -> CGRect {
        let baseBounds = activePathBounds(for: output, scale: scale)
        guard mode == .tile else { return baseBounds }

        let stepX = output.boundingRect.width * state.tileGap
        let stepY = output.boundingRect.height * state.tileGap

        return (-1...1).reduce(CGRect.null) { rowAcc, row in
            (-1...1).reduce(rowAcc) { acc, col in
                acc.union(baseBounds.offsetBy(dx: CGFloat(col) * stepX, dy: CGFloat(row) * stepY))
            }
        }
    }

    private func activePathBounds(for output: RenderOutput, scale: Double) -> CGRect {
        var bounds = CGRect.null
        let pad = exportPadding(scale: scale)

        func include(_ paths: [CGPath]) {
            for path in paths where !path.isEmpty {
                bounds = bounds.union(path.boundingBoxOfPath)
            }
        }

        if state.layerConfig.showFill || state.layerConfig.showGuideGrid {
            include(output.gridPaths)
        }
        if state.layerConfig.showConstruction {
            include(output.constructionPaths)
        }
        if state.layerConfig.showMotif {
            include(output.motifPaths)
            include(output.wovenPaths)
        }
        if state.bandConfig.showBands {
            include(output.bandPaths)
        }

        if bounds.isNull {
            bounds = output.boundingRect
        }

        return bounds.insetBy(dx: -pad, dy: -pad)
    }

    private func exportPadding(scale: Double) -> CGFloat {
        let motifWidth = CGFloat(state.displayConfig.lineWeight) * CGFloat(scale)
        let bandWidth = state.bandConfig.showBands ? motifWidth * 0.55 : 0
        let constructionWidth: CGFloat = state.layerConfig.showConstruction ? 0.45 : 0
        let guideWidth: CGFloat = state.layerConfig.showGuideGrid ? 0.8 : 0
        return max(4, motifWidth, bandWidth, constructionWidth, guideWidth) + 2
    }
}

enum ExportFormat: String, CaseIterable { case png, pdf, svg }
