import SwiftUI

struct TileRenderExport: View {
    let output: RenderOutput
    let exportBounds: CGRect
    @ObservedObject var vm: PatternViewModel
    let exportScale: Double

    var body: some View {
        ZStack {
            Color(vm.activeTheme.canvasBg)

            Canvas { context, size in
                let theme = vm.activeTheme
                let width = output.boundingRect.width
                let height = output.boundingRect.height
                let gap = vm.state.tileGap
                let stepX = width * gap
                let stepY = height * gap
                let lw = CGFloat(vm.state.displayConfig.lineWeight) * CGFloat(exportScale)

                for row in -1...1 {
                    for col in -1...1 {
                        let isCenter = row == 0 && col == 0
                        let opacity: Double = isCenter ? 1.0 : (gap < 0.5 ? 0.55 : 0.40)

                        let dx = CGFloat(col) * stepX - exportBounds.minX
                        let dy = CGFloat(row) * stepY - exportBounds.minY

                        var ctx = context
                        ctx.opacity = opacity
                        ctx.translateBy(x: dx, y: dy)

                        if vm.state.layerConfig.showFill {
                            for path in output.gridPaths {
                                ctx.fill(Path(path), with: .color(theme.fill))
                            }
                        }
                        if vm.state.layerConfig.showGuideGrid {
                            for path in output.gridPaths {
                                ctx.stroke(Path(path), with: .color(theme.guide), lineWidth: 0.8)
                            }
                        }
                        if vm.state.layerConfig.showConstruction {
                            for path in output.constructionPaths {
                                ctx.stroke(Path(path), with: .color(theme.construction), lineWidth: 0.45)
                            }
                        }
                        if vm.state.layerConfig.showMotif {
                            for path in output.motifPaths {
                                ctx.stroke(Path(path), with: .color(theme.motif), lineWidth: lw)
                            }
                        }
                        if vm.state.bandConfig.showBands {
                            let blw = lw * 0.55
                            for path in output.bandPaths {
                                ctx.stroke(Path(path), with: .color(theme.motif.opacity(0.40)), lineWidth: blw)
                            }
                        }
                        if !output.wovenPaths.isEmpty {
                            for path in output.wovenPaths {
                                ctx.stroke(Path(path), with: .color(theme.motif), lineWidth: lw)
                            }
                        }
                    }
                }
            }
        }
    }
}
