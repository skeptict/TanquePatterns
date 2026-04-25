import SwiftUI

struct TileCanvas: View {
    @ObservedObject var vm: PatternViewModel

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let theme = vm.activeTheme
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(theme.canvasBg))

                guard let output = vm.renderOutput else { return }

                let W = output.boundingRect.width
                let H = output.boundingRect.height
                let gap = vm.state.tileGap
                let stepX = W * gap
                let stepY = H * gap
                let lw = CGFloat(vm.state.displayConfig.lineWeight)

                for row in -1...1 {
                    for col in -1...1 {
                        let isCentre = row == 0 && col == 0
                        let opacity: Double = isCentre ? 1.0 : (gap < 0.5 ? 0.55 : 0.40)

                        let dx = CGFloat(col) * stepX - output.boundingRect.minX
                            + (size.width - W) / 2
                        let dy = CGFloat(row) * stepY - output.boundingRect.minY
                            + (size.height - H) / 2

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

                        if isCentre {
                            var border = Path()
                            border.addRect(CGRect(x: output.boundingRect.minX,
                                                  y: output.boundingRect.minY,
                                                  width: W, height: H))
                            ctx.stroke(border,
                                with: .color(theme.brass.opacity(0.5)),
                                style: StrokeStyle(lineWidth: 1, dash: [6, 3]))
                        }
                    }
                }
            }
            .background(vm.activeTheme.canvasBg)
        }
    }
}
