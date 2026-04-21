import Foundation

struct PatternDocumentState: Codable {
    var gridSpec: GridSpecState
    var displayConfig: DisplayConfig
    var layerConfig: LayerConfig
    var bandConfig: BandConfig
    var weaveMode: WeaveMode
    var tileGap: Double
    var lastMode: PatternMode

    static var `default`: PatternDocumentState {
        PatternDocumentState(
            gridSpec: GridSpecState(family: .hexagonal, columns: 4, rows: 3,
                                   spacing: 80, cellScale: 0.92, contactT: 0.28),
            displayConfig: DisplayConfig(themeID: .dark, lineWeight: 1.5),
            layerConfig: LayerConfig(showGuideGrid: false, showConstruction: false,
                                     showMotif: true, showFill: false),
            bandConfig: BandConfig(showBands: false, bandOffset: 8, bandCount: 1),
            weaveMode: .flat,
            tileGap: 1.0,
            lastMode: .pattern
        )
    }
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
enum ThemeID: String, Codable { case dark, chalk, night, paper }
