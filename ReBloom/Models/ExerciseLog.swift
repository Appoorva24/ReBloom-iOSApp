import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var id: UUID
    var date: Date
    var exerciseName: String
    var durationSeconds: Int
    var weekNumber: Int
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseName: String = "",
        durationSeconds: Int = 0,
        weekNumber: Int = 1
    ) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.durationSeconds = durationSeconds
        self.weekNumber = weekNumber
    }
}
