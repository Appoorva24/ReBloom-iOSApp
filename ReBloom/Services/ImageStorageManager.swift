import Foundation
import Supabase

/// Manages uploading and downloading images via Supabase Storage.
enum ImageStorageManager {
    private static let client = SupabaseManager.client
    private static let memoryBucket = "memories"
    private static let profileBucket = "profile-images"
    
    // MARK: - Memory Images
    
    /// Upload compressed image to Supabase Storage (memories bucket).
    /// Returns the public URL string for the uploaded image.
    static func uploadImage(imageData: Data, memoryID: UUID) async throws -> String {
        // Compress first using the existing ImageCompressor
        guard let compressed = ImageCompressor.compress(imageData, maxSizeKB: 500) else {
            throw StorageError.compressionFailed
        }
        
        let fileName = "\(memoryID.uuidString).jpg"
        
        // Upload to Supabase Storage (upsert to handle re-uploads)
        _ = try await client.storage
            .from(memoryBucket)
            .upload(
                path: fileName,
                file: compressed,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        // Get public URL
        let publicURL = try client.storage
            .from(memoryBucket)
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Download image data from a public URL.
    static func downloadImage(url: String) async throws -> Data {
        guard let imageURL = URL(string: url) else {
            throw StorageError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: imageURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StorageError.downloadFailed
        }
        
        return data
    }
    
    /// Delete an image from Supabase Storage (memories bucket).
    static func deleteImage(memoryID: UUID) async throws {
        let fileName = "\(memoryID.uuidString).jpg"
        _ = try await client.storage
            .from(memoryBucket)
            .remove(paths: [fileName])
    }
    
    // MARK: - Profile Images
    
    /// Upload a profile image to Supabase Storage (profile-images bucket).
    /// Returns the public URL string.
    static func uploadProfileImage(imageData: Data, userID: String) async throws -> String {
        guard let compressed = ImageCompressor.compress(imageData, maxSizeKB: 300) else {
            throw StorageError.compressionFailed
        }
        
        let fileName = "\(userID).jpg"
        
        _ = try await client.storage
            .from(profileBucket)
            .upload(
                path: fileName,
                file: compressed,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        let publicURL = try client.storage
            .from(profileBucket)
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Delete a profile image from Supabase Storage.
    static func deleteProfileImage(userID: String) async throws {
        let fileName = "\(userID).jpg"
        _ = try await client.storage
            .from(profileBucket)
            .remove(paths: [fileName])
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case downloadFailed
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress image."
        case .uploadFailed: return "Image upload failed."
        case .downloadFailed: return "Image download failed."
        case .invalidURL: return "Invalid image URL."
        }
    }
}
