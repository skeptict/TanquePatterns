# Tanque Patterns — CLAUDE.md

## Pre-Task Contract
Before touching any file, declare:
- Every file you will CREATE (with one-line purpose)
- Every file you will MODIFY (with what changes)
Wait for confirmation before proceeding.

## Hard Stops
- No AppKit/UIKit/SwiftUI imports inside Engine/ — pure Swift only
- No merge to main without explicit instruction
- No separate iOS target — single binary, macOS 14 minimum
- No GeometryReader (performance: use Canvas + PreferenceKey pattern instead)

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

## Completion Protocol
After every session, report:
1. Files created (with line counts)
2. Files modified (with summary of changes)
3. Build status (must be SUCCESS, zero errors, zero new warnings)
4. Any risks or follow-ups for next session
5. Update Open Brain via Tanque Open Brain MCP

## Key files
- Engine/Math/GeometryMath.swift — all vector primitives
- Engine/Generators/GridGenerator.swift — four grid families
- Engine/Recipes/ — MotifRecipe protocol + three conformers
- Engine/Weave/WeaveSolver.swift — over/under crossing solver
- Model/PatternDocumentState.swift — Codable working copy (ViewModel owns this)
- Model/PatternDocument.swift — SwiftData @Model (thin identity + JSON blob)
