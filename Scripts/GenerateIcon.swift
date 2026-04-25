#!/usr/bin/env swift
// GenerateIcon.swift — renders the 12-fold three-squares interlace star as a macOS app icon.
// Run with: swift Scripts/GenerateIcon.swift
// Writes 10 PNG files + Contents.json into AppIcon.appiconset.

import Foundation
import CoreGraphics
import AppKit

// MARK: - Geometry

func polar(cx: CGFloat, cy: CGFloat, r: CGFloat, angleDeg: CGFloat) -> CGPoint {
    let a = (angleDeg - 90) * .pi / 180
    return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a))
}

func tips(cx: CGFloat, cy: CGFloat, R: CGFloat) -> [CGPoint] {
    (0..<12).map { polar(cx: cx, cy: cy, r: R, angleDeg: CGFloat($0) * 30) }
}

func notches(cx: CGFloat, cy: CGFloat, R: CGFloat) -> [CGPoint] {
    let r = R * tan(15 * CGFloat.pi / 180)   // R * (2 - √3) ≈ R * 0.2679
    return (0..<12).map { polar(cx: cx, cy: cy, r: r, angleDeg: CGFloat($0) * 30 + 15) }
}

func squareCorners(sq: Int, tips t: [CGPoint]) -> [CGPoint] {
    [t[sq], t[sq + 3], t[sq + 6], t[sq + 9]]
}

// Returns (t along AB, t along CD) or nil if parallel / outside segments.
func segIntersect(_ A: CGPoint, _ B: CGPoint, _ C: CGPoint, _ D: CGPoint) -> (CGFloat, CGFloat)? {
    let dx1 = B.x - A.x, dy1 = B.y - A.y
    let dx2 = D.x - C.x, dy2 = D.y - C.y
    let denom = dx1 * dy2 - dy1 * dx2
    guard abs(denom) > 1e-9 else { return nil }
    let dx = C.x - A.x, dy = C.y - A.y
    let t = (dx * dy2 - dy * dx2) / denom
    let u = (dx * dy1 - dy * dx1) / denom
    return (t, u)
}

func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
}

// MARK: - Rendering

let brass      = CGColor(red: 201/255, green: 160/255, blue: 88/255, alpha: 1)
let brassFill  = CGColor(red: 201/255, green: 160/255, blue: 88/255, alpha: 0.08)
let brassGuide = CGColor(red: 201/255, green: 160/255, blue: 88/255, alpha: 0.25)
let brassDot   = CGColor(red: 201/255, green: 160/255, blue: 88/255, alpha: 0.6)
let bgColor    = CGColor(red: 0x0d/255, green: 0x0e/255, blue: 0x10/255, alpha: 1)

func renderIcon(size: Int) -> CGImage? {
    let w = CGFloat(size)
    let cx = w / 2, cy = w / 2
    let R = w * 0.38
    let strokeW = w * 0.028
    let gapPx   = w * 0.042

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    ctx.interpolationQuality = .high

    // 1. Background
    ctx.setFillColor(bgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: w))

    let t = tips(cx: cx, cy: cy, R: R)
    let n = notches(cx: cx, cy: cy, R: R)
    let squares = (0..<3).map { squareCorners(sq: $0, tips: t) }

    // 2. Guide ring (≥128px only)
    if size >= 128 {
        ctx.setStrokeColor(brassGuide)
        ctx.setLineWidth(strokeW * 0.3)
        let dashLen = CGFloat(size) / 64
        ctx.setLineDash(phase: 0, lengths: [dashLen, dashLen * 2])
        let gr = R * 1.06
        ctx.addEllipse(in: CGRect(x: cx - gr, y: cy - gr, width: gr * 2, height: gr * 2))
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: [])
    }

    // 3. Star outline path (12-pointed zigzag: tip → notch → tip → …)
    let starPath = CGMutablePath()
    for i in 0..<12 {
        starPath.addLine(to: t[i])
        starPath.addLine(to: n[i])
    }
    starPath.closeSubpath()

    // 3a. Fill with subtle brass
    ctx.addPath(starPath)
    ctx.setFillColor(brassFill)
    ctx.fillPath()

    // 4–6. Interlaced squares — draw back to front (sq2, sq1, sq0)
    for sqIdx in [2, 1, 0] {
        let sq = squares[sqIdx]
        let others = (0..<3).filter { $0 != sqIdx }.map { squares[$0] }

        ctx.setStrokeColor(brass)
        ctx.setLineWidth(strokeW * 1.05)
        ctx.setLineCap(.round)

        for edgeI in 0..<4 {
            let A = sq[edgeI]
            let B = sq[(edgeI + 1) % 4]
            let edgeLen = hypot(B.x - A.x, B.y - A.y)
            guard edgeLen > 0 else { continue }
            let halfGap = (gapPx / 2) / edgeLen

            // Collect all crossings along this edge from the other two squares
            var crossingTs: [CGFloat] = []
            for other in others {
                for otherEdge in 0..<4 {
                    let C = other[otherEdge]
                    let D = other[(otherEdge + 1) % 4]
                    if let (t1, t2) = segIntersect(A, B, C, D),
                       t1 > 0.001, t1 < 0.999, t2 > 0.001, t2 < 0.999 {
                        crossingTs.append(t1)
                    }
                }
            }
            crossingTs.sort()

            // Build gap ranges for under-crossings: isOver = (sqIdx + crossIdx) % 2 == 0
            var gapRanges: [(CGFloat, CGFloat)] = []
            for (crossIdx, crossT) in crossingTs.enumerated() {
                let isOver = (sqIdx + crossIdx) % 2 == 0
                if !isOver {
                    gapRanges.append((max(0, crossT - halfGap), min(1, crossT + halfGap)))
                }
            }

            // Draw edge with under-crossing gaps omitted
            var lastT: CGFloat = 0
            for (gapStart, gapEnd) in gapRanges {
                if lastT < gapStart {
                    ctx.move(to: lerp(A, B, lastT))
                    ctx.addLine(to: lerp(A, B, gapStart))
                    ctx.strokePath()
                }
                lastT = gapEnd
            }
            if lastT < 1.0 {
                ctx.move(to: lerp(A, B, lastT))
                ctx.addLine(to: lerp(A, B, 1.0))
                ctx.strokePath()
            }
        }
    }

    // 7. Star outline stroke
    ctx.addPath(starPath)
    ctx.setStrokeColor(brass)
    ctx.setLineWidth(strokeW * 0.65)
    ctx.setLineJoin(.miter)
    ctx.setMiterLimit(8)
    ctx.strokePath()

    // 8. Center dot
    let dotR = strokeW * 0.4
    ctx.setFillColor(brassDot)
    ctx.addEllipse(in: CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2))
    ctx.fillPath()

    return ctx.makeImage()
}

func pngData(from image: CGImage) -> Data? {
    let rep = NSBitmapImageRep(cgImage: image)
    return rep.representation(using: .png, properties: [:])
}

// MARK: - Sizes & output

let iconsetPath = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()             // Scripts/
    .deletingLastPathComponent()             // TanquePatterns/ (inner)
    .appendingPathComponent("TanquePatterns")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

let sizes: [(filename: String, px: Int)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]

try FileManager.default.createDirectory(at: iconsetPath, withIntermediateDirectories: true)

for (filename, px) in sizes {
    guard let image = renderIcon(size: px) else {
        print("ERROR: render failed for \(px)px"); continue
    }
    guard let png = pngData(from: image) else {
        print("ERROR: PNG encode failed for \(px)px"); continue
    }
    let dest = iconsetPath.appendingPathComponent(filename)
    try png.write(to: dest)
    print("  \(filename) — \(png.count) bytes")
}

let contentsJSON = """
{
  "images": [
    {"size":"16x16","idiom":"mac","filename":"icon_16x16.png","scale":"1x"},
    {"size":"16x16","idiom":"mac","filename":"icon_16x16@2x.png","scale":"2x"},
    {"size":"32x32","idiom":"mac","filename":"icon_32x32.png","scale":"1x"},
    {"size":"32x32","idiom":"mac","filename":"icon_32x32@2x.png","scale":"2x"},
    {"size":"128x128","idiom":"mac","filename":"icon_128x128.png","scale":"1x"},
    {"size":"128x128","idiom":"mac","filename":"icon_128x128@2x.png","scale":"2x"},
    {"size":"256x256","idiom":"mac","filename":"icon_256x256.png","scale":"1x"},
    {"size":"256x256","idiom":"mac","filename":"icon_256x256@2x.png","scale":"2x"},
    {"size":"512x512","idiom":"mac","filename":"icon_512x512.png","scale":"1x"},
    {"size":"512x512","idiom":"mac","filename":"icon_512x512@2x.png","scale":"2x"}
  ],
  "info":{"version":1,"author":"xcode"}
}
"""
let contentsURL = iconsetPath.appendingPathComponent("Contents.json")
try contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)
print("  Contents.json — written")
print("Done. \(sizes.count) icon files generated.")
