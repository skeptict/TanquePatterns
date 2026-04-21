struct HexStarRecipe: MotifRecipe {
    func constructionLines(for cell: GridCell, contactT: Double) -> [LineSeg] {
        cell.vertices.map { LineSeg(start: cell.center, end: $0) }
    }

    func motifArms(for cell: GridCell, contactT: Double) -> [ArmPoints] {
        brougArms(poly: cell.vertices, contactT: contactT)
    }
}
