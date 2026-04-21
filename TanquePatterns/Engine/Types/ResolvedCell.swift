struct ResolvedCell {
    let cell: GridCell
    let constructionLines: [LineSeg]
    let motifArms: [ArmPoints] // WeaveSolver needs the 3-point structure
}
