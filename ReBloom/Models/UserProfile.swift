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
    var inviteCode: String
    var partnerID: String?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        role: String = "wife",
        babyName: String = "",
        babyBirthDate: Date = Date(),
        partnerName: String = "",
        onboardingComplete: Bool = false,
        firstLaunchDate: Date = Date(),
        inviteCode: String = "",
        partnerID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.babyName = babyName
        self.babyBirthDate = babyBirthDate
        self.partnerName = partnerName
        self.onboardingComplete = onboardingComplete
        self.firstLaunchDate = firstLaunchDate
        self.inviteCode = inviteCode
        self.partnerID = partnerID
    }
    
    // MARK: - Computed Properties
    var postpartumWeek: Int {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: babyBirthDate, to: Date()).weekOfYear ?? 1
        return max(1, weeks)
    }
    
    var daysPostpartum: Int {
        let days = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
        return max(0, days)
    }
    
    var babyAgeFormatted: String {
        let weeks = postpartumWeek
        if weeks < 5 {
            return "\(weeks) week\(weeks == 1 ? "" : "s") old"
        } else {
            let months = weeks / 4
            return "\(months) month\(months == 1 ? "" : "s") old"
        }
    }
    
    var isPartnerConnected: Bool {
        partnerID != nil && !(partnerID?.isEmpty ?? true)
    }
}
