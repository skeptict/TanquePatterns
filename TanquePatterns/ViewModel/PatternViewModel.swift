import SwiftUI
import SwiftData
import Combine

@MainActor
final class PatternViewModel: ObservableObject {
    @Published var state: PatternDocumentState = .default
    @Published var renderOutput: RenderOutput? = nil
    @Published var animStep: Double = 0
    @Published var selectedCellIndex: Int? = nil

    private var saveTask: Task<Void, Never>?
    private var document: PatternDocument?

    // Autosave — debounced 400ms
    func scheduleAutosave(context: ModelContext) {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self.persist(context: context)
        }
    }

    private func persist(context: ModelContext) {
        document?.saveState(state)
        try? context.save()
    }

    // Geometry recompute — call after any state.gridSpec change
    func recompute() {
        // TODO: Session 2
    }
}
