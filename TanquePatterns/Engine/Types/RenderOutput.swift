import CoreGraphics

struct RenderOutput {
    let constructionPaths: [CGPath]
    let motifPaths: [CGPath]
    let wovenPaths: [CGPath]         // empty when weaveMode == .flat
    let gridPaths: [CGPath]          // cell outlines
    let bandPaths: [CGPath]          // strapwork offset arms
    let contactPointPaths: [CGPath]  // small circles at each contact point
    let motifPathsByCell: [[CGPath]] // index matches resolvedCells order
    let ribbonPaths: [CGPath]        // filled ribbon polygons (one per arm)
    let ribbonOutlinePaths: [CGPath] // outer edge strokes (two per arm)
    let boundingRect: CGRect
}
