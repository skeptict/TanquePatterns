# Tanque Patterns — CLAUDE.md

## Pre-Task Contract
Before touching any file, declare:
- Every file you will CREATE (with one-line purpose)
- Every file you will MODIFY (with what changes)
Wait for confirmation before proceeding.

## Standing Permissions

The following actions are pre-authorized for this project and do not require
individual confirmation:

- Read any file in the project directory
- Create new Swift source files in TanquePatterns/
- Edit any existing Swift source file in TanquePatterns/
- Delete files that are explicitly listed in the current session's Pre-Task Contract
- Run xcodebuild to verify builds and tests
- Run bash commands for file inspection (cat, grep, find, ls, wc, stat)
- Commit to the current branch with descriptive commit messages
- Call Tanque Open Brain MCP tools (capture_thought, search_thoughts, list_thoughts)

The following always require explicit confirmation before proceeding:

- Merging to main
- Deleting files NOT listed in the Pre-Task Contract
- Adding Swift Package dependencies
- Modifying TanquePatternsTests/ target membership or project structure
- Any changes outside the TanquePatterns/ project directory

## Self-verification
After every meaningful change, run this build command and fix all errors before proceeding:

```bash
xcodebuild \
  -project /Users/skeptict/Documents/GitHub/TanquePatterns/TanquePatterns/TanquePatterns.xcodeproj \
  -scheme TanquePatterns \
  -destination 'platform=macOS' \
  build 2>&1 | grep -E "error:|warning:|BUILD"
```

Run tests with:
```bash
xcodebuild \
  -project /Users/skeptict/Documents/GitHub/TanquePatterns/TanquePatterns/TanquePatterns.xcodeproj \
  -scheme TanquePatterns \
  -destination 'platform=macOS' \
  test 2>&1 | grep -E "error:|warning:|FAILED|passed|failed|BUILD"
```

Only report back when `BUILD SUCCEEDED` with zero errors.

## Hard Stops
- No AppKit/UIKit/SwiftUI imports inside Engine/ — pure Swift only
- No merge to main without explicit instruction
- No separate iOS target — single binary, macOS 14 minimum
- No GeometryReader in the engine layer (Canvas + size parameter is fine in Views)

## Architecture
- MVVM, @MainActor ViewModels
- SwiftData for persistence (PatternDocument @Model)
- Geometry engine: Engine/ directory, zero UI framework dependencies
- ModelContext passed as parameter from Views — never stored in ViewModel

## Known Footguns
- Swift concurrency: always Task { @MainActor in }, never bare Task { }
- regPoly phase: hexagons use phase=0 (flat-top), not -π/2
- SIMD2<Double> throughout engine; convert to CGFloat only at CGPath boundary
- WeaveSolver strand grouping: use 0.5pt tolerance for shared endpoint detection
- Canvas coordinate system: top-left origin; center pattern via offsetX/offsetY translation
- CGPath stroking: use context.stroke(Path(cgPath), ...) not context.draw on CGPath directly

## Completion Protocol
After every session, report:
1. Files created (with line counts)
2. Files modified (with summary of changes)
3. Build status (must be SUCCESS, zero errors, zero new warnings)
4. Any risks or follow-ups for next session
5. Update Open Brain via Tanque Open Brain MCP

## Key files
- Engine/Math/GeometryMath.swift — all vector primitives + brougArms
- Engine/Generators/GridGenerator.swift — four grid families
- Engine/Generators/MotifRecipeResolver.swift — applies armExtension (spacing * 0.15)
- Engine/Recipes/ — MotifRecipe protocol + three conformers
- Engine/Weave/WeaveSolver.swift — over/under crossing solver
- Engine/Rendering/PatternRenderer.swift — CGPath output
- Model/PatternDocumentState.swift — Codable working copy (ViewModel owns this)
- Model/PatternDocument.swift — SwiftData @Model (thin identity + JSON blob)
- ViewModel/PatternViewModel.swift — recompute() runs engine on detached Task
- Views/PatternCanvas.swift — SwiftUI Canvas, renders motifPaths
- Views/LeftPanel.swift — left panel, 256px (replaced MinimalControlPanel.swift in Session 3)
- Views/TitleBar.swift — 48px title bar with mode tabs, theme swatches, export button
- Views/ExportSheet.swift — PNG + PDF export UI
- Views/TileCanvas.swift — tile mode canvas (3×3 repeat)

## Codex session additions (2026-04-23/24)
- Export sheet: PNG and PDF via ImageRenderer + NSHostingView.dataWithPDF
- SwiftData persistence: PatternDocument attach/save, autosave debounced 400ms
- Export rendering: PatternRenderExport (Pattern mode) + TileRenderExport (Tile mode)
- Export clipping fix: translate by negative boundingRect origin before drawing
- PDF export: NSHostingView.dataWithPDF (not NSImage.pdfData — doesn't exist)
