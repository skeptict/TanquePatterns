import Foundation

typealias Vec2 = SIMD2<Double>

func lerp(_ a: Vec2, _ b: Vec2, t: Double) -> Vec2 {
    a + (b - a) * t
}

func normalize(_ v: Vec2) -> Vec2 {
    let len = (v.x * v.x + v.y * v.y).squareRoot()
    guard len > 1e-12 else { return .zero }
    return v / len
}

// 90° CCW rotation
func perp(_ v: Vec2) -> Vec2 {
    Vec2(-v.y, v.x)
}

func lineIntersect(_ p1: Vec2, _ p2: Vec2, _ p3: Vec2, _ p4: Vec2) -> Vec2? {
    let d1 = p2 - p1
    let d2 = p4 - p3
    let det = d1.x * d2.y - d1.y * d2.x
    guard abs(det) > 1e-9 else { return nil }
    let t = ((p3.x - p1.x) * d2.y - (p3.y - p1.y) * d2.x) / det
    return p1 + d1 * t
}

func centroid(_ points: [Vec2]) -> Vec2 {
    guard !points.isEmpty else { return .zero }
    return points.reduce(Vec2.zero, +) / Double(points.count)
}

func regularPolygon(center: Vec2, n: Int, radius: Double, phase: Double) -> [Vec2] {
    (0..<n).map { i in
        let angle = phase + Double(i) * 2.0 * .pi / Double(n)
        return center + Vec2(cos(angle), sin(angle)) * radius
    }
}

// Broug arm construction for any even regular polygon.
// outerA and outerB are contact points near each vertex; inner is their chord intersection.
func brougArms(poly: [Vec2], contactT: Double) -> [ArmPoints] {
    let n = poly.count
    guard n >= 4, n % 2 == 0 else { return [] }
    let half = n / 2

    return (0..<n).map { i in
        // end contact of edge (i-1), near poly[i]
        let outerA = lerp(poly[i], poly[(i - 1 + n) % n], t: contactT)
        // start contact of edge i, near poly[i]
        let outerB = lerp(poly[i], poly[(i + 1) % n], t: contactT)

        // Chord partners: connect each contact across the polygon (opposite edge)
        let oppA = (i - 1 + half + n) % n
        let partnerA = lerp(poly[oppA], poly[(oppA + 1) % n], t: contactT)

        let oppB = (i + half) % n
        let partnerB = lerp(poly[(oppB + 1) % n], poly[oppB], t: contactT)

        let inner = lineIntersect(outerA, partnerA, outerB, partnerB)
            ?? centroid(poly)

        return ArmPoints(outerA: outerA, inner: inner, outerB: outerB)
    }
}

func vec2Length(_ v: Vec2) -> Double {
    (v.x * v.x + v.y * v.y).squareRoot()
}

func vec2Distance(_ a: Vec2, _ b: Vec2) -> Double {
    vec2Length(a - b)
}
