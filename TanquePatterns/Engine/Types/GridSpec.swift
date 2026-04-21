struct GridSpec {
    let family: GridFamily
    let columns: Int      // 2–8
    let rows: Int         // 1–8
    let spacing: Double   // cell pitch in points, 52–140
    let cellScale: Double // polygon radius / spacing, 0.65–1.18
    let contactT: Double  // star depth, 0.10–0.45

    var cellRadius: Double { spacing * cellScale * 0.5 }
}
