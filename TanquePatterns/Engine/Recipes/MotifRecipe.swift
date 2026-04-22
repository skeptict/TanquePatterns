// Stateless — all parameters passed through method calls, no stored properties.
protocol MotifRecipe {
    func constructionLines(for cell: GridCell, contactT: Double) -> [LineSeg]
    func motifArms(for cell: GridCell, contactT: Double, armExtension: Double) -> [ArmPoints]
}

extension MotifRecipe {
    // Backward-compatible default: no extension applied.
    func motifArms(for cell: GridCell, contactT: Double) -> [ArmPoints] {
        motifArms(for: cell, contactT: contactT, armExtension: 0.0)
    }
}
