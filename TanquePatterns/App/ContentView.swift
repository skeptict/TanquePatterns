import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var vm = PatternViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var hasBootstrappedDocument = false

    var body: some View {
        VStack(spacing: 0) {
            TitleBar(vm: vm)
            HStack(spacing: 0) {
                LeftPanel(vm: vm)
                Group {
                    if vm.mode == .tile {
                        TileCanvas(vm: vm)
                    } else {
                        PatternCanvas(vm: vm)
                    }
                }
            }
        }
        .background(TP.bgApp)
        .ignoresSafeArea()
        .task {
            bootstrapDocumentIfNeeded()
        }
        .sheet(isPresented: $vm.isExportSheetPresented) {
            ExportSheet(vm: vm, isPresented: $vm.isExportSheetPresented)
        }
    }

    private func bootstrapDocumentIfNeeded() {
        guard !hasBootstrappedDocument else { return }

        let descriptor = FetchDescriptor<PatternDocument>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        let document = (try? modelContext.fetch(descriptor))?.first ?? createDefaultDocument()
        vm.attach(document: document, context: modelContext)
        hasBootstrappedDocument = true
    }

    private func createDefaultDocument() -> PatternDocument {
        let document = PatternDocument(name: "Untitled Pattern", state: .default)
        modelContext.insert(document)
        try? modelContext.save()
        return document
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PatternDocument.self, inMemory: true)
}
