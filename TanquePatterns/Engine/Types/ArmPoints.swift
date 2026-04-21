// A Broug arm: outer contact A, inner intersection point, outer contact B.
struct ArmPoints {
    let outerA: Vec2
    let inner: Vec2
    let outerB: Vec2
}

struct OffsetArmResult {
    let positive: ArmPoints
    let negative: ArmPoints
}

// Miter-capped parallel offset of an arm polyline. Miter limit: 6× distance.
func offsetArm(_ arm: ArmPoints, distance: Double) -> OffsetArmResult {
    let dir1 = normalize(arm.inner - arm.outerA)
    let dir2 = normalize(arm.outerB - arm.inner)
    let n1 = perp(dir1)
    let n2 = perp(dir2)
    let miterLimit = 6.0 * distance

    func offsetSide(_ sign: Double) -> ArmPoints {
        let d = sign * distance
        let a = arm.outerA + n1 * d
        let b = arm.inner  + n1 * d
        let c = arm.inner  + n2 * d
        let e = arm.outerB + n2 * d

        let miterPt: Vec2
        if let m = lineIntersect(a, b, c, e),
           vec2Distance(m, arm.inner) < miterLimit {
            miterPt = m
        } else {
            miterPt = arm.inner + (n1 + n2) * (d * 0.5)
        }
        return ArmPoints(outerA: a, inner: miterPt, outerB: e)
    }

    return OffsetArmResult(positive: offsetSide(1), negative: offsetSide(-1))
}
