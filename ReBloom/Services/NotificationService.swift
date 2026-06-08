import Foundation
import Supabase

/// Manages in-app notifications via the Supabase `notifications` table.
@Observable
final class NotificationService {
    // MARK: - State
    var notifications: [AppNotification] = []
    var unreadCount: Int = 0
    var isLoading = false
    var errorMessage: String?
    
    private let client = SupabaseManager.client
    
    // MARK: - Fetch Notifications
    /// Fetches all notifications for the given user from Supabase.
    func fetchNotifications(userID: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let rows: [AppNotification] = try await client.from("notifications")
                .select()
                .eq("user_id", value: userID)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.notifications = rows
                self.unreadCount = rows.filter { !$0.is_read }.count
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load notifications."
                self.isLoading = false
            }
            print("[Notifications] Fetch failed: \(error)")
        }
    }
    
    // MARK: - Mark as Read
    /// Marks a specific notification as read in Supabase.
    func markAsRead(notificationID: String) async {
        do {
            try await client.from("notifications")
                .update(["is_read": true])
                .eq("id", value: notificationID)
                .execute()
            
            await MainActor.run {
                if let index = notifications.firstIndex(where: { $0.id == notificationID }) {
                    let old = notifications[index]
                    notifications[index] = AppNotification(
                        id: old.id,
                        user_id: old.user_id,
                        type: old.type,
                        message: old.message,
                        is_read: true,
                        related_id: old.related_id,
                        created_at: old.created_at
                    )
                    unreadCount = notifications.filter { !$0.is_read }.count
                }
            }
        } catch {
            print("[Notifications] Mark-as-read failed: \(error)")
        }
    }
    
    // MARK: - Mark All as Read
    /// Marks all notifications as read for the given user.
    func markAllAsRead(userID: String) async {
        do {
            try await client.from("notifications")
                .update(["is_read": true])
                .eq("user_id", value: userID)
                .eq("is_read", value: false)
                .execute()
            
            await MainActor.run {
                notifications = notifications.map { n in
                    AppNotification(
                        id: n.id,
                        user_id: n.user_id,
                        type: n.type,
                        message: n.message,
                        is_read: true,
                        related_id: n.related_id,
                        created_at: n.created_at
                    )
                }
                unreadCount = 0
            }
        } catch {
            print("[Notifications] Mark-all-read failed: \(error)")
        }
    }
    
    // MARK: - Create Notification
    /// Inserts a new notification into the Supabase `notifications` table.
    func createNotification(
        type: NotificationType,
        recipientID: String,
        message: String,
        relatedID: String? = nil
    ) async {
        let notification = AppNotification(
            id: nil,
            user_id: recipientID,
            type: type.rawValue,
            message: message,
            is_read: false,
            related_id: relatedID,
            created_at: nil
        )
        
        do {
            try await client.from("notifications")
                .insert(notification)
                .execute()
        } catch {
            print("[Notifications] Create failed: \(error)")
        }
    }
}
