import Foundation

struct GridGenerator {
    func generate(spec: GridSpec) -> [GridCell] {
        switch spec.family {
        case .hexagonal:     return hexGrid(spec: spec)
        case .trihex:        return trihexGrid(spec: spec)
        case .squareFourfold: return squareFourfoldGrid(spec: spec)
        case .dodecagonal:   return dodecaGrid(spec: spec)
        }
    }

    // MARK: - Hex

    private func hexGrid(spec: GridSpec) -> [GridCell] {
        let hw = spec.spacing * sqrt(3.0) / 2.0
        var cells: [GridCell] = []
        for r in 0..<spec.rows {
            for c in 0..<spec.columns {
                let cx = Double(c) * hw * 2.0 + (r % 2 == 1 ? hw : 0) + hw
                let cy = Double(r) * spec.spacing * 1.5 + spec.spacing
                let center = Vec2(cx, cy)
                let verts = regularPolygon(center: center, n: 6,
                                           radius: spec.cellRadius, phase: 0)
                cells.append(GridCell(id: UUID(), type: .hexagon,
                                      center: center, vertices: verts, orientation: 0))
            }
        }
        return cells
    }

    // MARK: - Trihex (3.4.6.4 Archimedean)

    private func trihexGrid(spec: GridSpec) -> [GridCell] {
        let s = spec.spacing
        let t1x = s * (sqrt(3.0) + 1.0)
        let t2x = t1x / 2.0
        let t2y = t1x * sqrt(3.0) / 2.0

        // Build bounding box to filter cells
        let maxX = t1x * Double(spec.columns) + s
        let maxY = t2y * Double(spec.rows) + s

        var seen = Set<Int64>()
        var cells: [GridCell] = []

        func key(_ type: CellType, _ cx: Double, _ cy: Double) -> Int64 {
            let ti: Int64 = type == .hexagon ? 0 : type == .square ? 1 : 2
            let kx = Int64(bitPattern: UInt64(Int64(cx * 8).magnitude)) * 1_000_000
            let ky = Int64(bitPattern: UInt64(Int64(cy * 8).magnitude))
            return ti * 1_000_000_000_000 + kx + ky
        }

        func add(_ cell: GridCell) {
            let k = key(cell.type, cell.center.x, cell.center.y)
            guard !seen.contains(k) else { return }
            guard cell.center.x > -s, cell.center.x < maxX + s,
                  cell.center.y > -s, cell.center.y < maxY + s else { return }
            seen.insert(k)
            cells.append(cell)
        }

        for row in 0..<(spec.rows + 1) {
            for col in 0..<(spec.columns + 1) {
                let hx = Double(col) * t1x + Double(row) * t2x
                let hy = Double(row) * t2y
                let hCenter = Vec2(hx, hy)
                let hexVerts = regularPolygon(center: hCenter, n: 6,
                                              radius: spec.cellRadius, phase: 0)
                add(GridCell(id: UUID(), type: .hexagon,
                             center: hCenter, vertices: hexVerts, orientation: 0))

                // 6 surrounding squares and 6 surrounding triangles
                for i in 0..<6 {
                    let v0 = hexVerts[i]
                    let v1 = hexVerts[(i + 1) % 6]
                    let edgeMid = (v0 + v1) * 0.5
                    let _ = normalize(v1 - v0)
                    let inward = normalize(hCenter - edgeMid)

                    // Square: sits between two hex edges, center is offset from hex edge midpoint
                    let sqDist = spec.cellRadius * 0.5 + s * (sqrt(3.0) - 1.0) / 2.0
                    let sqCenter = edgeMid + inward * (-sqDist)
                    let sqVerts = regularPolygon(center: sqCenter, n: 4,
                                                 radius: spec.cellRadius * sqrt(2.0) / 2.0,
                                                 phase: atan2(inward.y, inward.x) + .pi / 4.0)
                    add(GridCell(id: UUID(), type: .square,
                                 center: sqCenter, vertices: sqVerts, orientation: 0))

                    // Triangle: in the gap between hex and two squares
                    let triCenter = edgeMid + inward * (-sqDist * 2.0)
                    let triVerts = regularPolygon(center: triCenter, n: 3,
                                                  radius: spec.cellRadius / sqrt(3.0),
                                                  phase: atan2(-inward.y, -inward.x) + .pi / 6.0)
                    add(GridCell(id: UUID(), type: .triangle,
                                 center: triCenter, vertices: triVerts, orientation: 0))
                }
            }
        }
        return cells
    }

    // MARK: - Square/Fourfold

    private func squareFourfoldGrid(spec: GridSpec) -> [GridCell] {
        var cells: [GridCell] = []
        for r in 0..<spec.rows {
            for c in 0..<spec.columns {
                let cx = Double(c) * spec.spacing + spec.spacing / 2.0
                let cy = Double(r) * spec.spacing + spec.spacing / 2.0
                let center = Vec2(cx, cy)
                let verts = regularPolygon(center: center, n: 4,
                                           radius: spec.cellRadius * sqrt(2.0),
                                           phase: -.pi / 4.0)
                cells.append(GridCell(id: UUID(), type: .square,
                                      center: center, vertices: verts, orientation: 0))
            }
        }
        return cells
    }

    // MARK: - Dodecagonal

    private func dodecaGrid(spec: GridSpec) -> [GridCell] {
        var cells: [GridCell] = []
        for r in 0..<spec.rows {
            for c in 0..<spec.columns {
                let cx = Double(c) * spec.spacing + spec.spacing / 2.0
                let cy = Double(r) * spec.spacing + spec.spacing / 2.0
                let center = Vec2(cx, cy)
                let verts = regularPolygon(center: center, n: 12,
                                           radius: spec.cellRadius * 0.96,
                                           phase: -.pi / 12.0)
                cells.append(GridCell(id: UUID(), type: .hexagon,
                                      center: center, vertices: verts, orientation: 0))
            }
        }
        return cells
    }
}
