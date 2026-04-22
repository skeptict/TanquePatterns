import SwiftUI
import SwiftData
import Combine

@MainActor
final class PatternViewModel: ObservableObject {
    @Published var state: PatternDocumentState = .default {
        didSet { recompute() }
    }
    @Published var renderOutput: RenderOutput? = nil
    @Published var animStep: Double = 0
    @Published var selectedCellIndex: Int? = nil

    private var saveTask: Task<Void, Never>?
    private var recomputeTask: Task<Void, Never>?
    private var document: PatternDocument?

    init() {
        recompute()
    }

    // Runs on MainActor; engine structs are fast enough for interactive use.
    // Move to Task.detached in a future session once nonisolated is added to engine types.
    func recompute() {
        recomputeTask?.cancel()
        let currentState = state
        recomputeTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            let spec = currentState.gridSpec.asGridSpec
            let cells = GridGenerator().generate(spec: spec)
            let resolved = MotifRecipeResolver().resolve(cells: cells, spec: spec)
            let output = PatternRenderer().render(
                cells: resolved,
                spec: spec,
                weaveMode: currentState.weaveMode,
                bandOffset: currentState.bandConfig.bandOffset,
                bandCount: currentState.bandConfig.showBands
                    ? currentState.bandConfig.bandCount : 0
            )
            guard !Task.isCancelled else { return }
            self.renderOutput = output
        }
    }

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
}
