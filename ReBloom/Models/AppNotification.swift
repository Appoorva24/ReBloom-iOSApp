import Foundation

/// Notification types for in-app events
enum NotificationType: String, Codable {
    case memoryShared = "memory_shared"
    case loveNoteReceived = "love_note_received"
    case missionCompleted = "mission_completed"
    case partnerConnected = "partner_connected"
}

/// Codable DTO matching the `notifications` Supabase table.
struct AppNotification: Codable, Identifiable {
    let id: String?
    let user_id: String
    let type: String
    let message: String
    let is_read: Bool
    let related_id: String?
    let created_at: String?
}
