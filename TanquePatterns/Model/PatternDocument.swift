import SwiftData
import Foundation

@Model
final class PatternDocument {
    var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var thumbnailData: Data?
    var specJSON: Data
    // Denormalized for list views — keep in sync on every save
    var familyRawValue: String
    var columns: Int
    var rows: Int

    init(name: String, state: PatternDocumentState) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.specJSON = (try? JSONEncoder().encode(state)) ?? Data()
        self.familyRawValue = state.gridSpec.family.rawValue
        self.columns = state.gridSpec.columns
        self.rows = state.gridSpec.rows
    }

    func loadState() -> PatternDocumentState {
        (try? JSONDecoder().decode(PatternDocumentState.self, from: specJSON)) ?? .default
    }

    func saveState(_ state: PatternDocumentState) {
        specJSON = (try? JSONEncoder().encode(state)) ?? specJSON
        familyRawValue = state.gridSpec.family.rawValue
        columns = state.gridSpec.columns
        rows = state.gridSpec.rows
        modifiedAt = Date()
    }
}
