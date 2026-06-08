import Foundation
import SwiftUI
import Supabase

/// DTO matching the `exercise_library` Supabase table columns.
struct SupabaseExerciseLibrary: Codable, Identifiable {
    let id: String?
    let name: String
    let icon: String?
    let benefit: String?
    let week_number: Int
    let animation_type: String?
    let steps: [String]?
    let color_hex: String?
}

/// Fetches exercise data from the Supabase `exercise_library` table for weeks 2-4.
/// Week 1 exercises remain hardcoded in ExerciseData.swift.
enum ExerciseLibraryService {
    private static let client = SupabaseManager.client
    
    /// In-memory cache keyed by week number.
    private static var cache: [Int: [Exercise]] = [:]
    
    /// Fetches exercises for a specific week from Supabase.
    /// Returns cached results if available.
    static func fetchExercises(weekNumber: Int) async throws -> [Exercise] {
        // Return cached if available
        if let cached = cache[weekNumber], !cached.isEmpty {
            return cached
        }
        
        let rows: [SupabaseExerciseLibrary] = try await client.from("exercise_library")
            .select()
            .eq("week_number", value: weekNumber)
            .execute()
            .value
        
        let exercises = rows.map { row in
            let animType: ExerciseAnimationType
            switch row.animation_type {
            case "deepBreathing":   animType = .deepBreathing
            case "pelvicFloorHold": animType = .pelvicFloorHold
            default:                animType = .deepBreathing
            }
            
            let color: Color
            if let hex = row.color_hex {
                color = Color(hex: hex)
            } else {
                color = .motherPrimary
            }
            
            return Exercise(
                name: row.name,
                icon: row.icon ?? "figure.mind.and.body",
                benefit: row.benefit ?? "",
                color: color,
                weekRange: weekNumber...weekNumber,
                animationType: animType,
                steps: row.steps ?? []
            )
        }
        
        cache[weekNumber] = exercises
        return exercises
    }
    
    /// Clears the in-memory cache.
    static func clearCache() {
        cache.removeAll()
    }
}
