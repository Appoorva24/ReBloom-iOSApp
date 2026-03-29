import Foundation
import SwiftData

@Model
final class LoveNote {
    var id: UUID
    var date: Date
    var senderRole: String
    var noteText: String
    var isRead: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        senderRole: String = "",
        noteText: String = "",
        isRead: Bool = false
    ) {
        self.id = id
        self.date = date
        self.senderRole = senderRole
        self.noteText = noteText
        self.isRead = isRead
    }
}
