import Foundation

struct PatternDocumentState: Codable {
    var gridSpec: GridSpecState
    var displayConfig: DisplayConfig
    var layerConfig: LayerConfig
    var bandConfig: BandConfig
    var weaveMode: WeaveMode
    var tileGap: Double
    var lastMode: PatternMode
    var ribbonSpec: RibbonSpec

    static var `default`: PatternDocumentState {
        PatternDocumentState(
            gridSpec: GridSpecState(family: .hexagonal, columns: 4, rows: 3,
                                   spacing: 80, cellScale: 1.00, contactT: 0.28),
            displayConfig: DisplayConfig(themeID: .dark, lineWeight: 1.5),
            layerConfig: LayerConfig(showGuideGrid: false, showConstruction: false,
                                     showMotif: true, showFill: false),
            bandConfig: BandConfig(showBands: false, bandOffset: 8, bandCount: 1),
            weaveMode: .flat,
            tileGap: 1.0,
            lastMode: .pattern,
            ribbonSpec: RibbonSpec.default
        )
    }

    // Custom decoder so existing saved docs without ribbonSpec still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gridSpec      = try c.decode(GridSpecState.self,   forKey: .gridSpec)
        displayConfig = try c.decode(DisplayConfig.self,   forKey: .displayConfig)
        layerConfig   = try c.decode(LayerConfig.self,     forKey: .layerConfig)
        bandConfig    = try c.decode(BandConfig.self,      forKey: .bandConfig)
        weaveMode     = try c.decode(WeaveMode.self,       forKey: .weaveMode)
        tileGap       = try c.decode(Double.self,          forKey: .tileGap)
        lastMode      = try c.decode(PatternMode.self,     forKey: .lastMode)
        ribbonSpec    = try c.decodeIfPresent(RibbonSpec.self, forKey: .ribbonSpec) ?? .default
    }

    init(gridSpec: GridSpecState, displayConfig: DisplayConfig, layerConfig: LayerConfig,
         bandConfig: BandConfig, weaveMode: WeaveMode, tileGap: Double,
         lastMode: PatternMode, ribbonSpec: RibbonSpec) {
        self.gridSpec      = gridSpec
        self.displayConfig = displayConfig
        self.layerConfig   = layerConfig
        self.bandConfig    = bandConfig
        self.weaveMode     = weaveMode
        self.tileGap       = tileGap
        self.lastMode      = lastMode
        self.ribbonSpec    = ribbonSpec
    }
}

struct RibbonSpec: Codable {
    var showRibbonFill: Bool
    var ribbonWidth: Double
    var ribbonColor: RibbonColor
    var outlineWidth: Double
    var showOutline: Bool
    var bgFillColor: BgFillColor
    var showBgFill: Bool

    static var `default`: RibbonSpec {
        RibbonSpec(showRibbonFill: false, ribbonWidth: 7.0, ribbonColor: .theme,
                   outlineWidth: 1.5, showOutline: true,
                   bgFillColor: .dark, showBgFill: false)
    }
}

enum RibbonColor: String, Codable, CaseIterable {
    case theme
    case motif
    case custom
}

enum BgFillColor: String, Codable, CaseIterable {
    case dark
    case light
    case theme
}

struct GridSpecState: Codable {
    var family: GridFamily
    var columns: Int
    var rows: Int
    var spacing: Double
    var cellScale: Double
    var contactT: Double

    var asGridSpec: GridSpec {
        GridSpec(family: family, columns: columns, rows: rows,
                 spacing: spacing, cellScale: cellScale, contactT: contactT)
    }
}

struct DisplayConfig: Codable {
    var themeID: ThemeID
    var lineWeight: Double
}

struct LayerConfig: Codable {
    var showGuideGrid: Bool
    var showConstruction: Bool
    var showMotif: Bool
    var showFill: Bool
}

struct BandConfig: Codable {
    var showBands: Bool
    var bandOffset: Double
    var bandCount: Int
}

enum PatternMode: String, Codable { case construct, pattern, tile, analyze }
enum ThemeID: String, Codable, CaseIterable { case dark, chalk, night, paper }
