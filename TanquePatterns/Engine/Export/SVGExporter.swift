import CoreGraphics
import Foundation

struct SVGExportSpec {
    let includeConstructionLines: Bool
    let includeGridLines: Bool
    let includeBands: Bool
    let backgroundColor: String
    let motifColor: String
    let constructionColor: String
    let gridColor: String
    let motifOpacity: Double
    let lineWeight: Double
    let includeRibbonFill: Bool
    let includeRibbonOutlines: Bool
    let ribbonColor: String
    let ribbonOutlineWidth: Double
}

struct SVGExporter {
    func export(output: RenderOutput, spec: SVGExportSpec) -> String {
        let W = output.boundingRect.width
        let H = output.boundingRect.height
        let tx = -output.boundingRect.minX
        let ty = -output.boundingRect.minY

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\""
        svg += "\n     width=\"\(fmt(W))\" height=\"\(fmt(H))\""
        svg += "\n     viewBox=\"0 0 \(fmt(W)) \(fmt(H))\">"
        svg += "\n  <rect width=\"100%\" height=\"100%\" fill=\"\(spec.backgroundColor)\"/>"
        svg += "\n  <g transform=\"translate(\(fmt(tx)),\(fmt(ty)))\">"
        svg += buildPatternContent(output: output, spec: spec)
        svg += "\n  </g>\n</svg>"
        return svg
    }

    func exportTile(output: RenderOutput, spec: SVGExportSpec, tileGap: Double) -> String {
        let baseRect = output.boundingRect
        let W = baseRect.width
        let H = baseRect.height
        let stepX = W * CGFloat(tileGap)
        let stepY = H * CGFloat(tileGap)
        let totalW = W + 2 * stepX
        let totalH = H + 2 * stepY
        let content = buildPatternContent(output: output, spec: spec)

        var svg = "<svg xmlns=\"http://www.w3.org/2000/svg\""
        svg += "\n     width=\"\(fmt(totalW))\" height=\"\(fmt(totalH))\""
        svg += "\n     viewBox=\"0 0 \(fmt(totalW)) \(fmt(totalH))\">"
        svg += "\n  <rect width=\"100%\" height=\"100%\" fill=\"\(spec.backgroundColor)\"/>"

        for row in -1...1 {
            for col in -1...1 {
                let dx = CGFloat(1 + col) * stepX - baseRect.minX
                let dy = CGFloat(1 + row) * stepY - baseRect.minY
                svg += "\n  <g transform=\"translate(\(fmt(dx)),\(fmt(dy)))\">"
                svg += content
                svg += "\n  </g>"
            }
        }

        svg += "\n</svg>"
        return svg
    }

    private func buildPatternContent(output: RenderOutput, spec: SVGExportSpec) -> String {
        var content = ""

        if spec.includeRibbonFill {
            content += pathGroup(paths: output.ribbonPaths,
                                 stroke: "none", opacity: 1.0,
                                 strokeWidth: 0, fill: spec.ribbonColor)
        }

        if spec.includeRibbonOutlines {
            content += pathGroup(paths: output.ribbonOutlinePaths,
                                 stroke: spec.ribbonColor, opacity: 1.0,
                                 strokeWidth: spec.ribbonOutlineWidth, fill: "none")
        }

        if spec.includeGridLines {
            content += pathGroup(paths: output.gridPaths,
                                 stroke: spec.gridColor, opacity: 0.06,
                                 strokeWidth: 0.8, fill: "none")
        }

        if spec.includeConstructionLines {
            content += pathGroup(paths: output.constructionPaths,
                                 stroke: spec.constructionColor, opacity: 0.45,
                                 strokeWidth: 0.45, fill: "none")
        }

        content += pathGroup(paths: output.motifPaths,
                             stroke: spec.motifColor,
                             opacity: spec.motifOpacity,
                             strokeWidth: spec.lineWeight,
                             fill: "none")

        if spec.includeBands {
            content += pathGroup(paths: output.bandPaths,
                                 stroke: spec.motifColor,
                                 opacity: spec.motifOpacity * 0.4,
                                 strokeWidth: spec.lineWeight * 0.55,
                                 fill: "none")
        }

        return content
    }

    private func pathGroup(paths: [CGPath], stroke: String, opacity: Double,
                           strokeWidth: Double, fill: String) -> String {
        guard !paths.isEmpty else { return "" }
        var g = "\n    <g stroke=\"\(stroke)\" stroke-opacity=\"\(fmt(opacity))\""
        g += " stroke-width=\"\(fmt(strokeWidth))\" fill=\"\(fill)\""
        g += " stroke-linecap=\"round\" stroke-linejoin=\"round\">"
        for path in paths {
            let d = cgPathToSVG(path)
            if !d.isEmpty {
                g += "\n      <path d=\"\(d)\"/>"
            }
        }
        g += "\n    </g>"
        return g
    }

    private func cgPathToSVG(_ path: CGPath) -> String {
        var d = ""
        path.applyWithBlock { element in
            let pts = element.pointee.points
            switch element.pointee.type {
            case .moveToPoint:
                d += "M\(fmt(pts[0].x)),\(fmt(pts[0].y)) "
            case .addLineToPoint:
                d += "L\(fmt(pts[0].x)),\(fmt(pts[0].y)) "
            case .addQuadCurveToPoint:
                d += "Q\(fmt(pts[0].x)),\(fmt(pts[0].y)) \(fmt(pts[1].x)),\(fmt(pts[1].y)) "
            case .addCurveToPoint:
                d += "C\(fmt(pts[0].x)),\(fmt(pts[0].y)) \(fmt(pts[1].x)),\(fmt(pts[1].y)) \(fmt(pts[2].x)),\(fmt(pts[2].y)) "
            case .closeSubpath:
                d += "Z "
            @unknown default:
                break
            }
        }
        return d.trimmingCharacters(in: .whitespaces)
    }

    private func fmt(_ v: CGFloat) -> String { String(format: "%.2f", v) }
    private func fmt(_ v: Double) -> String { String(format: "%.3f", v) }
}
