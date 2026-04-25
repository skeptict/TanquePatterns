import SwiftUI

/// Standalone pattern renderer for export — no canvas chrome, just the pattern at exact size
struct PatternRenderExport: View {
    let output: RenderOutput
    let exportBounds: CGRect
    @ObservedObject var vm: PatternViewModel
    let exportScale: Double

    var body: some View {
        ZStack {
            Color(vm.activeTheme.canvasBg)

            Canvas { context, size in
                let theme = vm.activeTheme
                let lw = CGFloat(vm.state.displayConfig.lineWeight) * CGFloat(exportScale)

                var ctx = context
                ctx.translateBy(x: -exportBounds.minX, y: -exportBounds.minY)

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
