import SwiftUI

struct PatternCanvas: View {
    @ObservedObject var vm: PatternViewModel

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(hex: "#0a0b0d"))
            )

            guard let output = vm.renderOutput else { return }

            let offsetX = (size.width  - output.boundingRect.width)  / 2 - output.boundingRect.minX
            let offsetY = (size.height - output.boundingRect.height) / 2 - output.boundingRect.minY

            var ctx = context
            ctx.translateBy(x: offsetX, y: offsetY)

            for path in output.motifPaths {
                ctx.stroke(
                    Path(path),
                    with: .color(Color(red: 0.90, green: 0.89, blue: 0.85).opacity(0.90)),
                    lineWidth: CGFloat(vm.state.displayConfig.lineWeight)
                )
            }

            if vm.state.layerConfig.showGuideGrid {
                for path in output.gridPaths {
                    ctx.stroke(
                        Path(path),
                        with: .color(.white.opacity(0.06)),
                        lineWidth: 0.8
                    )
                }
            }
        }
        .background(Color(hex: "#0a0b0d"))
    }
}
