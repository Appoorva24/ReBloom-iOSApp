import SwiftUI
import SwiftData

@Observable
final class HealViewModel {
    // MARK: - Data
    var exerciseLogs: [ExerciseLog] = []
    var profiles: [UserProfile] = []

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    var currentWeekNumber: Int {
        profile?.currentWeekNumber ?? 1
    }

    var currentDayInWeek: Int {
        profile?.currentDayInWeek ?? 1
    }

    var exercises: [Exercise] {
        exercisesForWeek(currentWeekNumber)
    }

    var completedRelativeDays: Set<Int> {
        guard let profile = profile else { return [] }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: profile.firstLaunchDate)
        let exerciseNames = Set(exercises.map { $0.name })
        var dayToNames: [Int: Set<String>] = [:]
        for log in exerciseLogs where log.completed {
            if let day = calendar.dateComponents([.day], from: startDay, to: calendar.startOfDay(for: log.date)).day {
                dayToNames[day, default: []].insert(log.exerciseName)
            }
        }

        return Set(dayToNames.compactMap { day, names in
            exerciseNames.isSubset(of: names) ? day : nil
        })
    }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        var exerciseDescriptor = FetchDescriptor<ExerciseLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        exerciseLogs = (try? modelContext.fetch(exerciseDescriptor)) ?? []

        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }
}
