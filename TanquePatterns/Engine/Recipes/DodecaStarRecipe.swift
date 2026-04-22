// Same Broug arm algorithm as HexStarRecipe, parameterized for n=12 via brougArms.
struct DodecaStarRecipe: MotifRecipe {
    func constructionLines(for cell: GridCell, contactT: Double) -> [LineSeg] {
        cell.vertices.map { LineSeg(start: cell.center, end: $0) }
    }

    func motifArms(for cell: GridCell, contactT: Double, armExtension: Double) -> [ArmPoints] {
        brougArms(poly: cell.vertices, contactT: contactT, armExtension: armExtension)
    }
}
