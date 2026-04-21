import Foundation

enum CellType: String, Codable {
    case hexagon, square, triangle
}

struct GridCell: Identifiable {
    let id: UUID
    let type: CellType
    let center: Vec2
    let vertices: [Vec2]    // world-space, clockwise order
    let orientation: Double // radians
}
