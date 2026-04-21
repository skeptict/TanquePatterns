import CoreGraphics

enum WeaveMode: String, Codable { case flat, woven }

struct ExportSpec {
    let scale: CGFloat
    let backgroundColor: CGColor
    let includeConstructionLines: Bool
    let includeGridLines: Bool
    let weaveMode: WeaveMode
}
