import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var vm = PatternViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 0) {
            MinimalControlPanel(vm: vm)
                .frame(width: 256)
            PatternCanvas(vm: vm)
        }
        .background(Color(hex: "#0d0e10"))
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
