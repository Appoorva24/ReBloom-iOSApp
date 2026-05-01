import Foundation
import SwiftData

@Model
final class PartnerMission {
    var id: UUID
    var date: Date
    var missionTitle: String
    var missionDescription: String
    var isCompleted: Bool
    var weekNumber: Int
    var isNewForPartner: Bool
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        missionTitle: String = "",
        missionDescription: String = "",
        isCompleted: Bool = false,
        weekNumber: Int = 1,
        isNewForPartner: Bool = true
    ) {
        self.id = id
        self.date = date
        self.missionTitle = missionTitle
        self.missionDescription = missionDescription
        self.isCompleted = isCompleted
        self.weekNumber = weekNumber
        self.isNewForPartner = isNewForPartner
    }
}
