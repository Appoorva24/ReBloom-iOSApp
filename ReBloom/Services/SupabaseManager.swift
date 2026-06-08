import Foundation
import Supabase

/// Central Supabase client — single source of truth for the backend connection.
enum SupabaseManager {
    
    // MARK: - Configuration
    // Your Supabase project credentials
    private static let supabaseURL  = URL(string: "https://jqvnzfywbmbknufxwwpx.supabase.co")!
    private static let supabaseKey  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impxdm56Znl3Ym1ia251Znh3d3B4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NDM3NDksImV4cCI6MjA5MzIxOTc0OX0.zYEIm8duBmMlil_BlENSXxtzsxRVJgJRgtoifcRBPrM"
    
    // MARK: - Shared Client
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseKey
    )
}
