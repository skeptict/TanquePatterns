import SwiftUI

struct Theme {
    let bgApp: Color
    let bgPanel: Color
    let bgSurf2: Color
    let bgSurf3: Color
    let border: Color
    let border2: Color
    let textPrim: Color
    let textMuted: Color
    let textMut2: Color
    let brass: Color
    let accent: Color

    static let dark = Theme(
        bgApp: Color(hex: "#0d0e10"), bgPanel: Color(hex: "#131416"),
        bgSurf2: Color(hex: "#1a1c1f"), bgSurf3: Color(hex: "#222427"),
        border: Color.white.opacity(0.07), border2: Color.white.opacity(0.12),
        textPrim: Color(hex: "#e3dfd8"), textMuted: Color(hex: "#6c6760"),
        textMut2: Color(hex: "#9a938b"), brass: Color(hex: "#c9a058"),
        accent: Color(hex: "#c9a058")
    )

    static let chalk = Theme(
        bgApp: Color(hex: "#f5f3ef"), bgPanel: Color(hex: "#ffffff"),
        bgSurf2: Color(hex: "#e8e6e1"), bgSurf3: Color(hex: "#d9d6d0"),
        border: Color.black.opacity(0.08), border2: Color.black.opacity(0.15),
        textPrim: Color(hex: "#1a1a1a"), textMuted: Color(hex: "#8a8580"),
        textMut2: Color(hex: "#4a4642"), brass: Color(hex: "#5a6d7a"),
        accent: Color(hex: "#5a6d7a")
    )

    static let night = Theme(
        bgApp: Color(hex: "#0a0a0c"), bgPanel: Color(hex: "#0f0f12"),
        bgSurf2: Color(hex: "#16161a"), bgSurf3: Color(hex: "#1c1c22"),
        border: Color.white.opacity(0.06), border2: Color.white.opacity(0.10),
        textPrim: Color(hex: "#d0cdd8"), textMuted: Color(hex: "#5a5560"),
        textMut2: Color(hex: "#8a8590"), brass: Color(hex: "#9580b8"),
        accent: Color(hex: "#9580b8")
    )

    static let paper = Theme(
        bgApp: Color(hex: "#faf9f7"), bgPanel: Color(hex: "#ffffff"),
        bgSurf2: Color(hex: "#f0eee9"), bgSurf3: Color(hex: "#e5e2dc"),
        border: Color.black.opacity(0.10), border2: Color.black.opacity(0.18),
        textPrim: Color(hex: "#1a1a1a"), textMuted: Color(hex: "#7a7570"),
        textMut2: Color(hex: "#3a3632"), brass: Color(hex: "#8b4a25"),
        accent: Color(hex: "#8b4a25")
    )

    static func theme(for id: ThemeID) -> Theme {
        switch id {
        case .dark: return .dark
        case .chalk: return .chalk
        case .night: return .night
        case .paper: return .paper
        }
    }
}

struct TP {
    @MainActor static var current: Theme { Theme.theme(for: PatternViewModel.sharedThemeID) }

    static let bgApp     = Color(hex: "#0d0e10")
    static let bgPanel   = Color(hex: "#131416")
    static let bgSurf2   = Color(hex: "#1a1c1f")
    static let bgSurf3   = Color(hex: "#222427")
    static let border    = Color.white.opacity(0.07)
    static let border2   = Color.white.opacity(0.12)
    static let textPrim  = Color(hex: "#e3dfd8")
    static let textMuted = Color(hex: "#6c6760")
    static let textMut2  = Color(hex: "#9a938b")
    static let brass     = Color(hex: "#c9a058")
}
