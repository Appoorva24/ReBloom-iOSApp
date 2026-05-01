import Foundation
import Supabase

/// Central Supabase client — single source of truth for the backend connection.
/// Replace the placeholder values below with your actual Supabase project credentials.
enum SupabaseManager {
    
    // MARK: - Configuration
    // TODO: Replace with your actual Supabase project URL and anon key
    private static let supabaseURL  = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
    private static let supabaseKey  = "YOUR_ANON_KEY"
    
    // MARK: - Shared Client
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
}
