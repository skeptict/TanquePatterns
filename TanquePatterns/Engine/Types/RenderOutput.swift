import CoreGraphics

struct RenderOutput {
    let constructionPaths: [CGPath]
    let motifPaths: [CGPath]
    let wovenPaths: [CGPath]   // empty when weaveMode == .flat
    let gridPaths: [CGPath]    // cell outlines for Analyze mode
    let bandPaths: [CGPath]    // strapwork offset arms
    let contactPointPaths: [CGPath]   // small circles at each contact point
    let motifPathsByCell: [[CGPath]]  // index matches resolvedCells order
    let boundingRect: CGRect
}
