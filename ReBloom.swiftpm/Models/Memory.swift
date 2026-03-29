import Foundation
import SwiftData

@Model
final class Memory {
    var id: UUID
    var date: Date
    var title: String
    var caption: String
    var imageData: Data
    var isSharedWithPartner: Bool
    var isNewForPartner: Bool   
    var sharedBy: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String = "",
        caption: String = "",
        imageData: Data = Data(),
        isSharedWithPartner: Bool = false,
        isNewForPartner: Bool = false,
        sharedBy: String = "mother"
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.caption = caption
        self.imageData = imageData
        self.isSharedWithPartner = isSharedWithPartner
        self.isNewForPartner = isNewForPartner
        self.sharedBy = sharedBy
    }
}
