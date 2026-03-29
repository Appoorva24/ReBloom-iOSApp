import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var id: UUID
    var date: Date
    var exerciseName: String
    var weekNumber: Int
    var completed: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        exerciseName: String = "",
        weekNumber: Int = 1,
        completed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.weekNumber = weekNumber
        self.completed = completed
    }
}
