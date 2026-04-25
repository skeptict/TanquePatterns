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
    let isBleed: Bool       // true for cells outside the requested grid bounds

    init(id: UUID, type: CellType, center: Vec2, vertices: [Vec2],
         orientation: Double, isBleed: Bool = false) {
        self.id = id
        self.type = type
        self.center = center
        self.vertices = vertices
        self.orientation = orientation
        self.isBleed = isBleed
    }
}
