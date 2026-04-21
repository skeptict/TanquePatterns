// Stateless — all parameters passed through method calls, no stored properties.
protocol MotifRecipe {
    func constructionLines(for cell: GridCell, contactT: Double) -> [LineSeg]
    func motifArms(for cell: GridCell, contactT: Double) -> [ArmPoints]
}
