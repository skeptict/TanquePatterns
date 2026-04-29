import SwiftUI

struct PatternCanvas: View {
    @ObservedObject var vm: PatternViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context, size in
                    let theme = vm.activeTheme
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(theme.canvasBg))

                    guard let output = vm.renderOutput else { return }

                    let offsetX = (size.width  - output.boundingRect.width)  / 2 - output.boundingRect.minX
                    let offsetY = (size.height - output.boundingRect.height) / 2 - output.boundingRect.minY

                    var ctx = context
                    ctx.translateBy(x: offsetX, y: offsetY)

                    switch vm.mode {
                    case .construct:
                        drawConstruct(ctx: &ctx, output: output)
                    default:
                        drawBase(ctx: &ctx, output: output)
                    }
                }

                if vm.mode == .construct {
                    constructLegend
                    constructProgressBar
                }

                if vm.mode == .analyze, let output = vm.renderOutput {
                    let offsetX = (geo.size.width  - output.boundingRect.width)  / 2 - output.boundingRect.minX
                    let offsetY = (geo.size.height - output.boundingRect.height) / 2 - output.boundingRect.minY
                    AnalyzeOverlay(vm: vm, offsetX: offsetX, offsetY: offsetY)
                }
            }
        }
    }

    // MARK: - Base draw (Pattern mode)

    private func drawBase(ctx: inout GraphicsContext, output: RenderOutput) {
        let theme = vm.activeTheme
        let lw = CGFloat(vm.state.displayConfig.lineWeight)

        if vm.state.layerConfig.showFill {
            for path in output.gridPaths {
                ctx.fill(Path(path), with: .color(theme.fill))
            }
        }
        if vm.state.ribbonSpec.showBgFill {
            let bgColor = resolvedBgFillColor(vm)
            for path in output.gridPaths {
                ctx.fill(Path(path), with: .color(bgColor))
            }
        }
        if vm.state.ribbonSpec.showRibbonFill {
            let rColor = resolvedRibbonColor()
            for path in output.ribbonPaths {
                ctx.fill(Path(path), with: .color(rColor))
            }
            if vm.state.ribbonSpec.showOutline {
                let olw = CGFloat(vm.state.ribbonSpec.outlineWidth)
                for path in output.ribbonOutlinePaths {
                    ctx.stroke(Path(path), with: .color(rColor), lineWidth: olw)
                }
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
        if vm.mode == .analyze, let sel = vm.selectedCellIndex {
            for path in output.motifPaths {
                ctx.stroke(Path(path), with: .color(theme.motif.opacity(0.20)), lineWidth: lw)
            }
            if sel < output.motifPathsByCell.count {
                for path in output.motifPathsByCell[sel] {
                    ctx.stroke(Path(path), with: .color(theme.brass), lineWidth: lw * 1.6)
                }
            }
            if sel < vm.resolvedCells.count {
                let cell = vm.resolvedCells[sel].cell
                for v in cell.vertices {
                    var p = Path()
                    p.move(to: CGPoint(x: cell.center.x, y: cell.center.y))
                    p.addLine(to: CGPoint(x: v.x, y: v.y))
                    ctx.stroke(p, with: .color(theme.brass.opacity(0.35)), lineWidth: 0.6)
                }
                let ctr = CGPoint(x: cell.center.x, y: cell.center.y)
                ctx.fill(Path(ellipseIn: CGRect(x: ctr.x - 3, y: ctr.y - 3, width: 6, height: 6)),
                         with: .color(theme.brass))
            }
        } else if vm.state.layerConfig.showMotif {
            if vm.state.weaveMode == .woven && !output.wovenPaths.isEmpty {
                for path in output.wovenPaths {
                    ctx.stroke(Path(path), with: .color(theme.motif), lineWidth: lw)
                }
            } else {
                for path in output.motifPaths {
                    ctx.stroke(Path(path), with: .color(theme.motif), lineWidth: lw)
                }
            }
        }
        if vm.state.bandConfig.showBands {
            let blw = lw * 0.55
            for path in output.bandPaths {
                ctx.stroke(Path(path), with: .color(theme.motif.opacity(0.40)), lineWidth: blw)
            }
        }
    }

    private func resolvedRibbonColor() -> Color {
        let theme = vm.activeTheme
        switch vm.state.ribbonSpec.ribbonColor {
        case .theme:  return theme.brass
        case .motif:  return theme.motif
        case .custom: return theme.brass
        }
    }

    private func resolvedBgFillColor(_ vm: PatternViewModel) -> Color {
        let theme = vm.activeTheme
        switch vm.state.ribbonSpec.bgFillColor {
        case .dark:
            return theme.isPaper
                ? Color(hex: "#c8b898").opacity(0.35)
                : Color(hex: "#1e1a14").opacity(1.0)
        case .light:
            return theme.isPaper
                ? Color(hex: "#f0e8d0").opacity(0.60)
                : Color(hex: "#e8dfc4").opacity(0.85)
        case .theme:
            return theme.brass.opacity(0.18)
        }
    }

    // MARK: - Construct draw

    private func drawConstruct(ctx: inout GraphicsContext, output: RenderOutput) {
        let theme = vm.activeTheme
        let ph = vm.animStep
        let lw = CGFloat(vm.state.displayConfig.lineWeight)

        let guideFrac  = ph < 0.25 ? ph / 0.25 : 1.0
        let constrFrac = ph < 0.25 ? 0.0 : ph < 0.50 ? (ph - 0.25) / 0.25 : 1.0
        let cptsFrac   = ph < 0.50 ? 0.0 : ph < 0.75 ? (ph - 0.50) / 0.25 : 1.0
        let motifFrac  = ph < 0.75 ? 0.0 : (ph - 0.75) / 0.25

        let visibleGuide  = Array(output.gridPaths.prefix(max(0, Int(ceil(guideFrac  * Double(output.gridPaths.count))))))
        let visibleConstr = Array(output.constructionPaths.prefix(max(0, Int(ceil(constrFrac * Double(output.constructionPaths.count))))))
        let visibleCpts   = Array(output.contactPointPaths.prefix(max(0, Int(ceil(cptsFrac * Double(output.contactPointPaths.count))))))
        let visibleMotif  = Array(output.motifPaths.prefix(max(0, Int(ceil(motifFrac  * Double(output.motifPaths.count))))))

        for path in visibleGuide {
            ctx.fill(Path(path), with: .color(theme.fill))
            ctx.stroke(Path(path), with: .color(theme.guide), lineWidth: 0.8)
        }
        for path in visibleConstr {
            ctx.stroke(Path(path), with: .color(theme.construction), lineWidth: 0.45)
        }
        for path in visibleCpts {
            ctx.fill(Path(path), with: .color(theme.contact))
        }
        for path in visibleMotif {
            ctx.stroke(Path(path), with: .color(theme.motif), lineWidth: lw)
        }
    }


    // MARK: - Construct overlays

    private var constructLegend: some View {
        VStack(alignment: .leading, spacing: 5) {
            legendRow(label: "Polygon scaffold",   active: vm.animStep > 0)
            legendRow(label: "Construction radii", active: vm.animStep > 0.25)
            legendRow(label: "Contact points",     active: vm.animStep > 0.50)
            legendRow(label: "Motif trace",         active: vm.animStep > 0.75)
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func legendRow(label: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(active ? vm.activeTheme.brass : TP.textMuted)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(active ? vm.activeTheme.brass : TP.textMuted)
        }
    }

    private var constructProgressBar: some View {
        VStack {
            Spacer()
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(TP.border)
                    .frame(width: 200, height: 2)
                Rectangle()
                    .fill(vm.activeTheme.brass)
                    .frame(width: max(0, 200 * vm.animStep), height: 2)
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Analyze overlay

struct AnalyzeOverlay: View {
    @ObservedObject var vm: PatternViewModel
    let offsetX: CGFloat
    let offsetY: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { vm.selectCell(nil) }

            ForEach(vm.resolvedCells.indices, id: \.self) { i in
                CellHitTarget(
                    cell: vm.resolvedCells[i].cell,
                    isSelected: vm.selectedCellIndex == i,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    onTap: { vm.selectCell(i) }
                )
            }
        }
    }
}

private struct CellHitTarget: View {
    let cell: GridCell
    let isSelected: Bool
    let offsetX: CGFloat
    let offsetY: CGFloat
    let onTap: () -> Void

    var body: some View {
        let pts = cell.vertices.map {
            CGPoint(x: CGFloat($0.x) + offsetX, y: CGFloat($0.y) + offsetY)
        }
        let cellPath = Path { path in
            guard let first = pts.first else { return }
            path.move(to: first)
            pts.dropFirst().forEach { path.addLine(to: $0) }
            path.closeSubpath()
        }

        ZStack {
            if isSelected {
                cellPath
                    .fill(Color(hex: "#c9a058").opacity(0.12))
                cellPath
                    .stroke(Color(hex: "#c9a058").opacity(0.7),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
            }
            cellPath
                .fill(Color.clear)
                .contentShape(cellPath)
                .onTapGesture(perform: onTap)
        }
    }
}
