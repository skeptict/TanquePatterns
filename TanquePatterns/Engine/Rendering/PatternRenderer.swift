import CoreGraphics
import Foundation

struct PatternRenderer {
    func render(cells: [ResolvedCell], spec: GridSpec,
                weaveMode: WeaveMode, bandOffset: Double, bandCount: Int) -> RenderOutput {

        let snapped = snapPass(cells, spec: spec)
        let visibleCells = snapped.filter { !$0.cell.isBleed }

        let constructionPaths = visibleCells.flatMap { cell in
            cell.constructionLines.map { seg in
                let p = CGMutablePath()
                p.move(to: CGPoint(seg.start))
                p.addLine(to: CGPoint(seg.end))
                return p as CGPath
            }
        }

        let motifPathsByCell = visibleCells.map { cell in
            cell.motifArms.map { arm -> CGPath in
                let p = CGMutablePath()
                p.move(to: CGPoint(arm.outerA))
                p.addLine(to: CGPoint(arm.inner))
                p.addLine(to: CGPoint(arm.outerB))
                return p as CGPath
            }
        }

        let motifPaths = motifPathsByCell.flatMap { $0 }

        let gridPaths = visibleCells.map { cell -> CGPath in
            let p = CGMutablePath()
            guard let first = cell.cell.vertices.first else { return p }
            p.move(to: CGPoint(first))
            cell.cell.vertices.dropFirst().forEach { p.addLine(to: CGPoint($0)) }
            p.closeSubpath()
            return p as CGPath
        }

        let contactPointPaths = visibleCells.filter { $0.cell.type != .triangle }.flatMap { cell in
            cell.motifArms.flatMap { arm -> [CGPath] in
                [arm.outerA, arm.outerB].map { pt in
                    let r = 2.5
                    let p = CGMutablePath()
                    p.addEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
                    return p as CGPath
                }
            }
        }

        let wovenPaths: [CGPath]
        if weaveMode == .woven {
            let solver = WeaveSolver()
            let strands = solver.solve(cells: visibleCells)
            wovenPaths = strands.flatMap { strand in
                strand.segments.map { seg in strandPath(seg) }
            }
        } else {
            wovenPaths = []
        }

        let bandPaths: [CGPath] = (1...max(1, bandCount)).flatMap { band in
            let dist = bandOffset * Double(band)
            return visibleCells.flatMap { cell in
                cell.motifArms.flatMap { arm -> [CGPath] in
                    let result = offsetArm(arm, distance: dist)
                    return [result.positive, result.negative].map { offsetted in
                        let p = CGMutablePath()
                        p.move(to: CGPoint(offsetted.outerA))
                        p.addLine(to: CGPoint(offsetted.inner))
                        p.addLine(to: CGPoint(offsetted.outerB))
                        return p as CGPath
                    }
                }
            }
        }

        let boundingRect = visibleCells.reduce(CGRect.null) { acc, cell in
            acc.union(cellBoundingRect(cell, padding: spec.spacing / 2.0))
        }

        return RenderOutput(
            constructionPaths: constructionPaths,
            motifPaths: motifPaths,
            wovenPaths: wovenPaths,
            gridPaths: gridPaths,
            bandPaths: bandPaths,
            contactPointPaths: contactPointPaths,
            motifPathsByCell: motifPathsByCell,
            boundingRect: boundingRect
        )
    }

    // MARK: - Private

    private struct IndexedArm {
        var arm: ArmPoints
        let cellID: UUID
    }

    private func snapPass(_ resolved: [ResolvedCell], spec: GridSpec) -> [ResolvedCell] {
        var indexed: [IndexedArm] = resolved.flatMap { rc in
            rc.motifArms.map { IndexedArm(arm: $0, cellID: rc.cell.id) }
        }
        let tolerance = spec.spacing * 0.08
        for i in indexed.indices {
            for j in (i+1)..<indexed.count {
                guard indexed[i].cellID != indexed[j].cellID else { continue }
                let checks: [(Vec2, Vec2, Bool, Bool)] = [
                    (indexed[i].arm.outerA, indexed[j].arm.outerA, true,  true),
                    (indexed[i].arm.outerA, indexed[j].arm.outerB, true,  false),
                    (indexed[i].arm.outerB, indexed[j].arm.outerA, false, true),
                    (indexed[i].arm.outerB, indexed[j].arm.outerB, false, false),
                ]
                for (p1, p2, isAi, isAj) in checks {
                    if vec2Distance(p1, p2) < tolerance {
                        let mid = (p1 + p2) * 0.5
                        if isAi { indexed[i].arm = ArmPoints(outerA: mid, inner: indexed[i].arm.inner, outerB: indexed[i].arm.outerB) }
                        else     { indexed[i].arm = ArmPoints(outerA: indexed[i].arm.outerA, inner: indexed[i].arm.inner, outerB: mid) }
                        if isAj { indexed[j].arm = ArmPoints(outerA: mid, inner: indexed[j].arm.inner, outerB: indexed[j].arm.outerB) }
                        else     { indexed[j].arm = ArmPoints(outerA: indexed[j].arm.outerA, inner: indexed[j].arm.inner, outerB: mid) }
                        break
                    }
                }
            }
        }
        var armIdx = 0
        return resolved.map { rc in
            let count = rc.motifArms.count
            let snappedArms = indexed[armIdx..<armIdx+count].map(\.arm)
            armIdx += count
            return ResolvedCell(cell: rc.cell, constructionLines: rc.constructionLines, motifArms: Array(snappedArms))
        }
    }

    private let defaultGapWidth = 4.0

    private func strandPath(_ seg: StrandSegment) -> CGPath {
        let arm = seg.arm
        let totalLen = vec2Distance(arm.outerA, arm.inner) + vec2Distance(arm.inner, arm.outerB)
        guard totalLen > 0 else { return CGMutablePath() }

        let gapHalf = defaultGapWidth / totalLen / 2.0
        let p = CGMutablePath()
        var drawing = true
        var lastT = 0.0

        func pointAt(_ t: Double) -> CGPoint {
            CGPoint(armPoint(arm, t: t))
        }

        for gapT in seg.gapAt {
            let gapStart = max(0, gapT - gapHalf)
            let gapEnd   = min(1, gapT + gapHalf)
            if drawing {
                if lastT == 0 { p.move(to: pointAt(lastT)) }
                p.addLine(to: pointAt(gapStart))
            }
            lastT = gapEnd
            drawing = true
        }

        if drawing {
            if lastT == 0 { p.move(to: pointAt(0)) }
            p.addLine(to: pointAt(1))
        }

        return p
    }

    private func armPoint(_ arm: ArmPoints, t: Double) -> Vec2 {
        let len1 = vec2Distance(arm.outerA, arm.inner)
        let len2 = vec2Distance(arm.inner, arm.outerB)
        let total = len1 + len2
        guard total > 0 else { return arm.inner }
        let split = len1 / total
        if t <= split {
            return lerp(arm.outerA, arm.inner, t: split > 0 ? t / split : 0)
        } else {
            return lerp(arm.inner, arm.outerB, t: (1 - split) > 0 ? (t - split) / (1 - split) : 0)
        }
    }

    private func cellBoundingRect(_ cell: ResolvedCell, padding: Double) -> CGRect {
        guard !cell.cell.vertices.isEmpty else { return .null }
        let xs = cell.cell.vertices.map(\.x)
        let ys = cell.cell.vertices.map(\.y)
        return CGRect(
            x: xs.min()! - padding, y: ys.min()! - padding,
            width: (xs.max()! - xs.min()!) + padding * 2,
            height: (ys.max()! - ys.min()!) + padding * 2
        )
    }
}

private extension CGPoint {
    init(_ v: Vec2) { self.init(x: v.x, y: v.y) }
}
