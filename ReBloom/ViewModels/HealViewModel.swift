import SwiftUI
import SwiftData

@Observable
final class HealViewModel {
    // MARK: - Data
    var exerciseLogs: [ExerciseLog] = []
    var profiles: [UserProfile] = []
    
    // MARK: - Remote Exercises
    var remoteExercises: [Exercise] = []
    var isLoadingExercises = false
    var exerciseError: String?

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    var currentWeekNumber: Int {
        profile?.currentWeekNumber ?? 1
    }

    var currentDayInWeek: Int {
        profile?.currentDayInWeek ?? 1
    }

    /// Combined exercises: Week 1 from hardcoded data, Weeks 2-4 from Supabase.
    var exercises: [Exercise] {
        if currentWeekNumber <= 1 {
            return exercisesForWeek(1)
        } else {
            // Use remote exercises if loaded, otherwise show week 1 as fallback
            return remoteExercises.isEmpty ? exercisesForWeek(1) : remoteExercises
        }
    }

    var completedRelativeDays: Set<Int> {
        guard let profile = profile else { return [] }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: profile.firstLaunchDate)
        let exerciseNames = Set(exercises.map { $0.name })
        var dayToNames: [Int: Set<String>] = [:]
        for log in exerciseLogs {
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
    
    // MARK: - Load Remote Exercises
    /// Fetches exercises for weeks 2-4 from the Supabase exercise_library table.
    func loadExercises() async {
        let week = currentWeekNumber
        guard week > 1 else { return }
        
        await MainActor.run {
            isLoadingExercises = true
            exerciseError = nil
        }
        
        do {
            let fetched = try await ExerciseLibraryService.fetchExercises(weekNumber: week)
            await MainActor.run {
                self.remoteExercises = fetched
                self.isLoadingExercises = false
            }
        } catch {
            await MainActor.run {
                self.exerciseError = "Failed to load exercises."
                self.isLoadingExercises = false
                // Fallback: keep showing week 1 exercises
            }
            print("[Heal] Exercise fetch failed: \(error)")
        }
    }
}
