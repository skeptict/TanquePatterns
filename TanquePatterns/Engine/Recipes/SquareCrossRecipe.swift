// Lateral X-cross connector for square cells in the trihex tiling.
// Connects contact points diagonally across opposite edge pairs.
struct SquareCrossRecipe: MotifRecipe {
    func constructionLines(for cell: GridCell, contactT: Double) -> [LineSeg] {
        cell.vertices.map { LineSeg(start: cell.center, end: $0) }
    }

    func motifArms(for cell: GridCell, contactT: Double) -> [ArmPoints] {
        let v = cell.vertices
        guard v.count == 4 else { return [] }
        var arms: [ArmPoints] = []

        // Two opposite edge pairs: (0,2) and (1,3)
        for (ei, ej) in [(0, 2), (1, 3)] {
            let a = lerp(v[ei],           v[(ei + 1) % 4], t: contactT)
            let b = lerp(v[(ei + 1) % 4], v[ei],           t: contactT)
            let c = lerp(v[ej],           v[(ej + 1) % 4], t: contactT)
            let d = lerp(v[(ej + 1) % 4], v[ej],           t: contactT)

            // Diagonal cross: a→d and b→c
            let x1 = lineIntersect(a, d, b, c) ?? centroid(v)
            arms.append(ArmPoints(outerA: a, inner: x1, outerB: d))
            arms.append(ArmPoints(outerA: b, inner: x1, outerB: c))
        }

        return arms
    }
}
