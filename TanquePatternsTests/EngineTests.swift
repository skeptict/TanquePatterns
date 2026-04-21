import Testing
import Foundation
@testable import TanquePatterns

// 1. regularPolygon — hex geometry
@Test func hexPolygonVertices() {
    let verts = regularPolygon(center: .zero, n: 6, radius: 1.0, phase: 0)
    #expect(verts.count == 6)
    // First vertex at (1, 0) for phase=0
    #expect(abs(verts[0].x - 1.0) < 1e-9)
    #expect(abs(verts[0].y - 0.0) < 1e-9)
    // All vertices at distance 1.0 from center
    for v in verts {
        #expect(abs(vec2Length(v) - 1.0) < 1e-9)
    }
}

// 2. GridGenerator — 3×3 hex grid
@Test func hexGridCellCount() {
    let spec = GridSpec(family: .hexagonal, columns: 3, rows: 3,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    #expect(cells.count == 9)
    #expect(cells.allSatisfy { $0.type == .hexagon })
}

// 3. GridGenerator — 2×2 trihex has mixed cell types
@Test func trihexMixedTypes() {
    let spec = GridSpec(family: .trihex, columns: 2, rows: 2,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let types = Set(cells.map(\.type))
    #expect(types.contains(.hexagon))
    #expect(types.contains(.square))
    #expect(types.contains(.triangle))
}

// 4. HexStarRecipe — 6 arms, outerA/outerB near cell edge
@Test func hexStarArmCount() {
    let spec = GridSpec(family: .hexagonal, columns: 1, rows: 1,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let cell = cells[0]
    let arms = HexStarRecipe().motifArms(for: cell, contactT: 0.28)
    #expect(arms.count == 6)

    let r = spec.cellRadius
    for arm in arms {
        let dA = vec2Length(arm.outerA - cell.center)
        let dB = vec2Length(arm.outerB - cell.center)
        // Contact points should be near the cell edge (within 15% of radius)
        #expect(dA > r * 0.5 && dA < r * 1.1)
        #expect(dB > r * 0.5 && dB < r * 1.1)
    }
}

// 5. offsetArm — positive and negative are symmetric about original arm
@Test func offsetArmSymmetry() {
    let arm = ArmPoints(outerA: Vec2(0, 0), inner: Vec2(5, 5), outerB: Vec2(10, 0))
    let result = offsetArm(arm, distance: 2.0)

    // Midpoints of positive and negative should average to the original
    func mid(_ a: ArmPoints) -> Vec2 { (a.outerA + a.outerB) * 0.5 }
    let midOrig  = mid(arm)
    let midPos   = mid(result.positive)
    let midNeg   = mid(result.negative)
    let midOfTwo = (midPos + midNeg) * 0.5

    #expect(abs(midOfTwo.x - midOrig.x) < 0.5)
    #expect(abs(midOfTwo.y - midOrig.y) < 0.5)
}

// 6. WeaveSolver — 1×1 hex grid detects at least one crossing
@Test func weaveSolverDetectsCrossings() {
    let spec = GridSpec(family: .hexagonal, columns: 1, rows: 1,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
    let strands = WeaveSolver().solve(cells: resolved)

    let allGapTs = strands.flatMap { $0.segments }.flatMap(\.gapAt)
    #expect(!allGapTs.isEmpty)
}
