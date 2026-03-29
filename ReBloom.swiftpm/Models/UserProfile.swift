import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var role: String
    var babyName: String
    var babyBirthDate: Date
    var partnerName: String
    var onboardingComplete: Bool
    var firstLaunchDate: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        role: String = "mother",
        babyName: String = "",
        babyBirthDate: Date = Date(),
        partnerName: String = "",
        onboardingComplete: Bool = false,
        firstLaunchDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.babyName = babyName
        self.babyBirthDate = babyBirthDate
        self.partnerName = partnerName
        self.onboardingComplete = onboardingComplete
        self.firstLaunchDate = firstLaunchDate
    }

    var weeksPostpartum: Int {
        let days = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
        return max(1, days / 7)
    }

    var daysPostpartum: Int {
        let days = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
        return max(1, days)
    }

   
    var daysSinceStart: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: firstLaunchDate)
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(0, days)
    }

   
    var currentWeekNumber: Int {
        (daysSinceStart / 7) + 1
    }

  
    var currentDayInWeek: Int {
        (daysSinceStart % 7) + 1
    }
}
