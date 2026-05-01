import UIKit
import Foundation

enum ImageCompressor {
    
    /// Compress image data to JPEG with target quality, optionally capping file size.
    static func compress(_ data: Data, maxSizeKB: Int = 500, quality: CGFloat = 0.7) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        var currentQuality = quality
        var compressed = image.jpegData(compressionQuality: currentQuality)
        
        // Iteratively reduce quality if over size limit
        while let c = compressed, c.count > maxSizeKB * 1024, currentQuality > 0.1 {
            currentQuality -= 0.1
            compressed = image.jpegData(compressionQuality: currentQuality)
        }
        
        return compressed
    }
    
    /// Create a thumbnail version of the image.
    static func thumbnail(_ data: Data, maxDimension: CGFloat = 300) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        guard ratio < 1.0 else {
            // Already small enough
            return image.jpegData(compressionQuality: 0.8)
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resized.jpegData(compressionQuality: 0.8)
    }
}
