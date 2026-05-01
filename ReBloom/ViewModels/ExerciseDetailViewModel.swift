import SwiftUI
import SwiftData

@Observable
final class ExerciseDetailViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []

    // MARK: - State
    var exerciseState: ExerciseDetailView.ExerciseState = .notStarted
    var seconds: Int = 0
    var timer: Timer?
    var showDurationSheet = false
    var selectedDuration: Int?

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }

    // MARK: - Actions
    func startExercise() {
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { exerciseState = .active }
        seconds = 0
        startTimer()
    }

    func pauseExercise() {
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { exerciseState = .paused }
        timer?.invalidate(); timer = nil
    }

    func resumeExercise() {
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { exerciseState = .active }
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.seconds += 1
            if let duration = self.selectedDuration, self.seconds >= duration {
                self.completeExercise()
            }
        }
    }

    func completeExercise() {
        timer?.invalidate(); timer = nil
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { exerciseState = .completed }
    }

    func logExercise(exerciseName: String, modelContext: ModelContext) {
        let log = ExerciseLog(
            exerciseName: exerciseName,
            weekNumber: profile?.weeksPostpartum ?? 1,
            completed: true
        )
        modelContext.insert(log)
        try? modelContext.save()
    }

    func endExerciseFully(exerciseName: String, modelContext: ModelContext) {
        timer?.invalidate(); timer = nil
        logExercise(exerciseName: exerciseName, modelContext: modelContext)
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
            exerciseState = .notStarted
            seconds = 0
        }
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}
