import Foundation
import SwiftData

@Model
final class MoodLog {
    var id: UUID
    var date: Date
    var mood: String
    var energyLevel: Int
    var journalNote: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: String = "",
        energyLevel: Int = 3,
        journalNote: String = ""
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energyLevel = energyLevel
        self.journalNote = journalNote
    }
}
