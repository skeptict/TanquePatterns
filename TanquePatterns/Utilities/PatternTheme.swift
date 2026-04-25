import SwiftUI

struct PatternTheme {
    let canvasBg: Color
    let brass: Color
    let motif: Color
    let guide: Color
    let construction: Color
    let fill: Color
    let contact: Color
    let isPaper: Bool

    static let dark = PatternTheme(
        canvasBg:     Color(hex: "#0a0b0d"),
        brass:        Color(hex: "#c9a058"),
        motif:        Color(red: 0.90, green: 0.89, blue: 0.85).opacity(0.90),
        guide:        Color.white.opacity(0.06),
        construction: Color(hex: "#c9a058").opacity(0.45),
        fill:         Color(hex: "#c9a058").opacity(0.09),
        contact:      Color(hex: "#c9a058").opacity(0.80),
        isPaper:      false
    )
    static let chalk = PatternTheme(
        canvasBg:     Color(hex: "#16172a"),
        brass:        Color(hex: "#9580b8"),
        motif:        Color(red: 0.86, green: 0.84, blue: 0.96).opacity(0.88),
        guide:        Color(hex: "#c8beff").opacity(0.07),
        construction: Color(hex: "#9580b8").opacity(0.45),
        fill:         Color(hex: "#9580b8").opacity(0.10),
        contact:      Color(hex: "#9580b8").opacity(0.85),
        isPaper:      false
    )
    static let night = PatternTheme(
        canvasBg:     Color(hex: "#080e14"),
        brass:        Color(hex: "#5aafaa"),
        motif:        Color(red: 0.78, green: 0.94, blue: 0.93).opacity(0.88),
        guide:        Color(hex: "#5ab4af").opacity(0.07),
        construction: Color(hex: "#5aafaa").opacity(0.40),
        fill:         Color(hex: "#5aafaa").opacity(0.10),
        contact:      Color(hex: "#5aafaa").opacity(0.85),
        isPaper:      false
    )
    static let paper = PatternTheme(
        canvasBg:     Color(hex: "#e8e0cc"),
        brass:        Color(hex: "#8b4a25"),
        motif:        Color(red: 0.12, green: 0.08, blue: 0.05).opacity(0.86),
        guide:        Color.black.opacity(0.07),
        construction: Color(hex: "#8b4a25").opacity(0.45),
        fill:         Color(hex: "#8b4a25").opacity(0.08),
        contact:      Color(hex: "#8b4a25").opacity(0.80),
        isPaper:      true
    )

    static func theme(for id: ThemeID) -> PatternTheme {
        switch id {
        case .dark:  return .dark
        case .chalk: return .chalk
        case .night: return .night
        case .paper: return .paper
        }
    }
}
