import SwiftUI
import SwiftData

struct HealView: View {
    @Query(sort: \ExerciseLog.date, order: .reverse) private var exerciseLogs: [ExerciseLog]
    @Query private var profiles: [UserProfile]

    @State private var appeared = true

    private var profile: UserProfile? { profiles.first }

    private var currentWeekNumber: Int {
        profile?.currentWeekNumber ?? 1
    }

    private var currentDayInWeek: Int {
        profile?.currentDayInWeek ?? 1
    }

    private var exercises: [Exercise] {
        exercisesForWeek(currentWeekNumber)
    }

    private var completedRelativeDays: Set<Int> {
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

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.motherBgTop, .motherBgBottom], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        weekBanner
                            .cardAppear(index: 0, appeared: appeared)

                        weekDayStrip
                            .cardAppear(index: 1, appeared: appeared)

                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                exerciseCard(exercise, dayIndex: index)
                            }
                            .buttonStyle(.plain)
                            .cardAppear(index: index + 2, appeared: appeared)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Heal")
            .onAppear {

            }
        }
    }

  
    private var weekBanner: some View {
        VStack(spacing: 10) {
            Text("Week \(currentWeekNumber)")
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [.motherPrimary, .motherGold],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: Color.motherPrimary.opacity(0.3), radius: 6, x: 0, y: 3)

            Text("Your gentle recovery starts here. Take it one breath at a time. 🌸")
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

  
    private var weekDayStrip: some View {
        let weekStartOffset = ((currentWeekNumber - 1) * 7)

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                let relativeDayIndex = weekStartOffset + index
                let dayNumber = index + 1
                let isToday     = dayNumber == currentDayInWeek
                let isCompleted = completedRelativeDays.contains(relativeDayIndex)
                let isFuture    = dayNumber > currentDayInWeek

                VStack(spacing: 6) {
                    Text("Day \(dayNumber)")
                        .font(.system(size: 9, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(isToday ? Color.motherPrimary : Color.motherTextBody)

                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                isCompleted
                                    ? LinearGradient(colors: [.motherPrimary, .motherGold],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white, Color.white],
                                                     startPoint: .top, endPoint: .bottom)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        isToday ? Color.motherPrimary : (isCompleted ? Color.clear : Color.gray.opacity(0.20)),
                                        lineWidth: isToday ? 2 : 1
                                    )
                            )
                            .shadow(color: Color.motherPrimary.opacity(isCompleted ? 0.18 : 0.06),
                                    radius: 4, x: 0, y: 2)

                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        } else if !isFuture {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(width: 36, height: 36)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
    }


    private func exerciseCard(_ exercise: Exercise, dayIndex: Int) -> some View {
        HStack(spacing: 16) {
            ExerciseAnimationView(type: exercise.animationType, size: 80)
                .frame(width: 80, height: 80)
                .background(exercise.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)

                Text("Day \(currentDayInWeek)")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextBody)

                Text(exercise.benefit)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextBody)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
