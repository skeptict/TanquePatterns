import Testing
import Foundation
@testable import TanquePatterns

// 1. regularPolygon — hex geometry
@Test func hexPolygonVertices() {
    let verts = regularPolygon(center: .zero, n: 6, radius: 1.0, phase: 0)
    #expect(verts.count == 6)
    #expect(abs(verts[0].x - 1.0) < 1e-9)
    #expect(abs(verts[0].y - 0.0) < 1e-9)
    for v in verts {
        #expect(abs(vec2Length(v) - 1.0) < 1e-9)
    }
}

// 2. GridGenerator — 3×3 hex grid produces exactly 9 visible (non-bleed) cells
@Test func hexGridCellCount() {
    let spec = GridSpec(family: .hexagonal, columns: 3, rows: 3,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let visible = cells.filter { !$0.isBleed }
    #expect(visible.count == 9)
    #expect(visible.allSatisfy { $0.type == .hexagon })
}

// 3. GridGenerator — 2×2 trihex has mixed cell types
@Test func trihexMixedTypes() {
    let spec = GridSpec(family: .trihex, columns: 2, rows: 2,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let visible = cells.filter { !$0.isBleed }
    let types = Set(visible.map(\.type))
    #expect(types.contains(.hexagon))
    #expect(types.contains(.square))
    #expect(types.contains(.triangle))
}

// 4. HexStarRecipe — 6 arms, outerA/outerB near cell edge.
// Hex radius = hw * cellScale = spacing * sqrt(3)/2 * cellScale (not spec.cellRadius).
@Test func hexStarArmCount() {
    let spec = GridSpec(family: .hexagonal, columns: 1, rows: 1,
                        spacing: 80, cellScale: 0.92, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    // Pick the single visible cell (bleed ring surrounds it)
    guard let cell = cells.first(where: { !$0.isBleed }) else {
        Issue.record("No visible cell generated for 1×1 hex grid")
        return
    }
    let arms = HexStarRecipe().motifArms(for: cell, contactT: 0.28)
    #expect(arms.count == 6)

    let hexRadius = spec.spacing * sqrt(3.0) / 2.0 * spec.cellScale
    for arm in arms {
        let dA = vec2Length(arm.outerA - cell.center)
        let dB = vec2Length(arm.outerB - cell.center)
        #expect(dA > hexRadius * 0.5 && dA < hexRadius * 1.1)
        #expect(dB > hexRadius * 0.5 && dB < hexRadius * 1.1)
    }
}

// 5. offsetArm — positive and negative are symmetric about original arm
@Test func offsetArmSymmetry() {
    let arm = ArmPoints(outerA: Vec2(0, 0), inner: Vec2(5, 5), outerB: Vec2(10, 0))
    let result = offsetArm(arm, distance: 2.0)

    func mid(_ a: ArmPoints) -> Vec2 { (a.outerA + a.outerB) * 0.5 }
    let midOrig  = mid(arm)
    let midPos   = mid(result.positive)
    let midNeg   = mid(result.negative)
    let midOfTwo = (midPos + midNeg) * 0.5

    #expect(abs(midOfTwo.x - midOrig.x) < 0.5)
    #expect(abs(midOfTwo.y - midOrig.y) < 0.5)
}

// 6. WeaveSolver — crossing detection with explicitly constructed overlapping arms.
@Test func weaveSolverDetectsCrossings() {
    let armA = ArmPoints(outerA: Vec2(-10, -10), inner: Vec2(0, 0), outerB: Vec2(10, -10))
    let armB = ArmPoints(outerA: Vec2(-10,  10), inner: Vec2(0, 0), outerB: Vec2(10,  10))
    let fakeCell = GridCell(id: UUID(), type: .hexagon, center: .zero, vertices: [], orientation: 0)
    let resolved = ResolvedCell(cell: fakeCell, constructionLines: [], motifArms: [armA, armB])
    let strands = WeaveSolver().solve(cells: [resolved])

    let allGapTs = strands.flatMap { $0.segments }.flatMap(\.gapAt)
    #expect(!allGapTs.isEmpty)
}

// 7. Hex vertex coincidence — same-row adjacent visible cells share exact vertex coordinates.
// At cellScale=1.0, hex radius = hw and center-to-center = 2*hw, so the right tip of
// cell[0] and left tip of cell[1] land on the same point (distance < 1e-10).
@Test func hexVertexCoincidence() {
    let spec = GridSpec(family: .hexagonal, columns: 2, rows: 1,
                        spacing: 80, cellScale: 1.0, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let visible = cells.filter { !$0.isBleed }
    #expect(visible.count == 2)

    var minDist = Double.infinity
    for i in 0..<6 {
        for j in 0..<6 {
            let d = vec2Distance(visible[0].vertices[i], visible[1].vertices[j])
            if d < minDist { minDist = d }
        }
    }
    #expect(minDist < 1e-6)
}

// 8. Export: render output has non-zero bounding rect
@Test func patternExportProducesNonEmptyBoundingRect() {
    let state = PatternDocumentState.default
    let spec = state.gridSpec.asGridSpec
    let cells = GridGenerator().generate(spec: spec)
    let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
    let output = PatternRenderer().render(
        cells: resolved, spec: spec,
        weaveMode: .flat, bandOffset: 0, bandCount: 0
    )
    #expect(output.boundingRect.width > 0)
    #expect(output.boundingRect.height > 0)
}

// 9. Export clipping regression: renderer returns true (negative-origin) bounding rect,
// not zero-clamped, so the export layer can apply the correct translation offset.
@Test func boundingRectOriginIsUnclamped() {
    let spec = GridSpec(family: .hexagonal, columns: 4, rows: 3,
                        spacing: 80, cellScale: 0.96, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
    let output = PatternRenderer().render(
        cells: resolved, spec: spec,
        weaveMode: .flat, bandOffset: 0, bandCount: 0
    )
    #expect(output.boundingRect != .null)
    // padding (spacing/2 = 40pt) extends beyond the first cell's leftmost vertex,
    // so minX and minY are negative — confirming raw geometry, not clamped to 0
    #expect(output.boundingRect.minX < 0)
    #expect(output.boundingRect.minY < 0)
}

// 10. Bleed cells are generated beyond the requested bounds
@Test func bleedCellsGeneratedBeyondBounds() {
    let spec = GridSpec(family: .hexagonal, columns: 3, rows: 2,
                        spacing: 80, cellScale: 0.96, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let bleedCells = cells.filter { $0.isBleed }
    let visibleCells = cells.filter { !$0.isBleed }
    #expect(visibleCells.count == 6)   // 3×2
    #expect(bleedCells.count > 0)
}

// 11. Bleed cell pipeline counts — 4×3 hex grid
// GridGenerator loop: r in -1...3 (5 values) × c in -1...4 (6 values) = 30 total
// Visible (non-bleed): rows 0-2 × cols 0-3 = 12
// MotifRecipeResolver and PatternRenderer both receive all 30; render() filters to 12 internally
@Test func bleedCellPipelineCounts() {
    let spec = GridSpec(family: .hexagonal, columns: 4, rows: 3,
                        spacing: 80, cellScale: 0.96, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    #expect(cells.count == 30)
    #expect(cells.filter { !$0.isBleed }.count == 12)

    let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
    #expect(resolved.count == 30)  // resolver sees all cells including bleed

    let output = PatternRenderer().render(cells: resolved, spec: spec,
                                          weaveMode: .flat, bandOffset: 0, bandCount: 0)
    // motifPathsByCell is built from visibleCells inside render(), so must be 12
    #expect(output.motifPathsByCell.count == 12)
    #expect(output.gridPaths.count == 12)
}

// 12. Renderer excludes bleed cells from path output
@Test func rendererExcludesBleedCells() {
    let spec = GridSpec(family: .hexagonal, columns: 3, rows: 2,
                        spacing: 80, cellScale: 0.96, contactT: 0.28)
    let cells = GridGenerator().generate(spec: spec)
    let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
    let output = PatternRenderer().render(cells: resolved, spec: spec,
                                          weaveMode: .flat, bandOffset: 0, bandCount: 0)
    // motifPathsByCell count must match visible cells only
    #expect(output.motifPathsByCell.count == 6)
}
