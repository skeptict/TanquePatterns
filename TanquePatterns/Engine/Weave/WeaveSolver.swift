import Foundation

struct WovenStrand {
    let segments: [StrandSegment]
}

struct StrandSegment {
    let arm: ArmPoints
    let gapAt: [Double] // t values (0–1 along arm) where this strand passes under another
}

struct WeaveSolver {
    private let gapHalfWidth = 0.04 // fraction of arm length to hide on each side of crossing

    func solve(cells: [ResolvedCell]) -> [WovenStrand] {
        let allArms = cells.flatMap(\.motifArms)
        guard !allArms.isEmpty else { return [] }

        // Find all crossings between arm segments
        var underT: [[Double]] = Array(repeating: [], count: allArms.count)

        for i in 0..<allArms.count {
            for j in (i + 1)..<allArms.count {
                let crossings = crossingsBetween(allArms[i], armB: allArms[j])
                for crossing in crossings {
                    // Alternating over/under: sort crossings globally by position index
                    let globalIdx = (i * allArms.count + j) % 2
                    if globalIdx == 0 {
                        underT[j].append(crossing.tB)
                    } else {
                        underT[i].append(crossing.tA)
                    }
                }
            }
        }

        // Group arms into strands by shared endpoints (tolerance 0.5pt)
        let strands = groupIntoStrands(arms: allArms)

        return strands.map { armIndices in
            let segments = armIndices.map { idx in
                StrandSegment(arm: allArms[idx], gapAt: underT[idx].sorted())
            }
            return WovenStrand(segments: segments)
        }
    }

    // MARK: - Private

    private struct Crossing {
        let tA: Double
        let tB: Double
        let point: Vec2
    }

    private func crossingsBetween(_ armA: ArmPoints, armB: ArmPoints) -> [Crossing] {
        var crossings: [Crossing] = []

        // Each arm has two sub-segments: outerA→inner and inner→outerB
        let segsA: [(Vec2, Vec2)] = [(armA.outerA, armA.inner), (armA.inner, armA.outerB)]
        let segsB: [(Vec2, Vec2)] = [(armB.outerA, armB.inner), (armB.inner, armB.outerB)]

        let lenA = vec2Distance(armA.outerA, armA.inner) + vec2Distance(armA.inner, armA.outerB)
        let lenB = vec2Distance(armB.outerA, armB.inner) + vec2Distance(armB.inner, armB.outerB)

        for (ai, segA) in segsA.enumerated() {
            for segB in segsB {
                guard let pt = lineIntersect(segA.0, segA.1, segB.0, segB.1) else { continue }

                // Verify intersection is within both segments
                let tSegA = paramOnSegment(pt, from: segA.0, to: segA.1)
                let tSegB = paramOnSegment(pt, from: segB.0, to: segB.1)
                guard (0...1).contains(tSegA), (0...1).contains(tSegB) else { continue }

                // Convert to full-arm t (0=outerA, 1=outerB)
                let segALen = vec2Distance(segA.0, segA.1)
                let offsetA = ai == 0 ? 0.0 : vec2Distance(armA.outerA, armA.inner)
                let tA = lenA > 0 ? (offsetA + tSegA * segALen) / lenA : 0.5

                let segBIdx = segsB.firstIndex(where: { $0.0 == segB.0 && $0.1 == segB.1 }) ?? 0
                let segBLen = vec2Distance(segB.0, segB.1)
                let offsetB = segBIdx == 0 ? 0.0 : vec2Distance(armB.outerA, armB.inner)
                let tB = lenB > 0 ? (offsetB + tSegB * segBLen) / lenB : 0.5

                crossings.append(Crossing(tA: tA, tB: tB, point: pt))
            }
        }

        return crossings
    }

    private func paramOnSegment(_ pt: Vec2, from a: Vec2, to b: Vec2) -> Double {
        let ab = b - a
        let len2 = ab.x * ab.x + ab.y * ab.y
        guard len2 > 1e-12 else { return 0 }
        return ((pt.x - a.x) * ab.x + (pt.y - a.y) * ab.y) / len2
    }

    private func groupIntoStrands(arms: [ArmPoints]) -> [[Int]] {
        let tolerance = 0.5
        var visited = Set<Int>()
        var strands: [[Int]] = []

        for start in 0..<arms.count {
            guard !visited.contains(start) else { continue }
            var strand: [Int] = []
            var queue = [start]
            while !queue.isEmpty {
                let idx = queue.removeFirst()
                guard !visited.contains(idx) else { continue }
                visited.insert(idx)
                strand.append(idx)
                // Find arms that share an endpoint with arms[idx]
                for j in 0..<arms.count where !visited.contains(j) {
                    if sharesEndpoint(arms[idx], arms[j], tolerance: tolerance) {
                        queue.append(j)
                    }
                }
            }
            strands.append(strand)
        }

        return strands
    }

    private func sharesEndpoint(_ a: ArmPoints, _ b: ArmPoints, tolerance: Double) -> Bool {
        let endpoints = [a.outerA, a.outerB]
        let others = [b.outerA, b.outerB]
        return endpoints.contains(where: { ea in
            others.contains(where: { vec2Distance(ea, $0) < tolerance })
        })
    }
}
