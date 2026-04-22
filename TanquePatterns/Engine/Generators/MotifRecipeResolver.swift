struct MotifRecipeResolver {
    func resolve(cells: [GridCell], spec: GridSpec) -> [ResolvedCell] {
        let armExtension = spec.spacing * 0.15
        return cells.map { cell in
            let recipe: (any MotifRecipe)?
            switch (cell.type, spec.family) {
            case (.hexagon, .dodecagonal):
                recipe = DodecaStarRecipe()
            case (.hexagon, _):
                recipe = HexStarRecipe()
            case (.square, .trihex):
                recipe = SquareCrossRecipe()
            case (.square, _):
                recipe = HexStarRecipe()
            case (.triangle, _):
                recipe = nil
            }

            guard let recipe else {
                return ResolvedCell(cell: cell, constructionLines: [], motifArms: [])
            }

            return ResolvedCell(
                cell: cell,
                constructionLines: recipe.constructionLines(for: cell, contactT: spec.contactT),
                motifArms: recipe.motifArms(for: cell, contactT: spec.contactT,
                                            armExtension: armExtension)
            )
        }
    }
}
