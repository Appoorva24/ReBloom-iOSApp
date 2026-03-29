import SwiftUI
import SwiftData

public struct MasonryGrid: View {
    let memories: [Memory]
    let onTap: (Memory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(memories, id: \.self) { memory in
                    Button {
                        onTap(memory)
                    } label: {
                        MemoryTile(memory: memory)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private struct MemoryTile: View {
        let memory: Memory

        private var uiImage: UIImage? {
            guard let data = memory.imageData else { return nil }
            return UIImage(data: data)
        }

        private var imageAspectRatio: CGFloat {
            guard let image = uiImage else { return 1 }
            return image.size.width > 0 ? image.size.height / image.size.width : 1
        }

        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    if let image = uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.width * imageAspectRatio)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: geo.size.width, height: geo.size.width)
                    }
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.75), .clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(memory.title ?? "")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding([.horizontal, .bottom], 8)
                }
                .frame(height: geo.size.width * imageAspectRatio)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12, style: .continuous)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}

#if DEBUG
// Provide a local mock Memory type and preview data if Memory is unavailable
fileprivate struct MockMemory: Hashable {
    let id = UUID()
    let imageData: Data?
    let title: String?
    let date: Date?

    init(title: String, color: UIColor, size: CGSize = CGSize(width: 200, height: 300)) {
        self.title = title
        self.date = Date()
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        self.imageData = img.jpegData(compressionQuality: 0.8)
    }
}

extension MockMemory {
    var toMemoryLike: MemoryLike {
        MemoryLike(imageData: imageData, title: title, date: date)
    }
}

// Since we don't have the actual Memory type, create a minimal MemoryLike struct for preview
fileprivate struct MemoryLike: Hashable, Identifiable {
    var id = UUID()
    var imageData: Data?
    var title: String?
    var date: Date?
}

fileprivate struct MasonryGridForPreview: View {
    let memories: [MemoryLike]

    var body: some View {
        MasonryGridPreview(memories: memories) { _ in }
    }

    private struct MasonryGridPreview: View {
        let memories: [MemoryLike]
        let onTap: (MemoryLike) -> Void

        private let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        var body: some View {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(memories, id: \.self) { memory in
                        Button {
                            onTap(memory)
                        } label: {
                            MemoryTile(memory: memory)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }

        private struct MemoryTile: View {
            let memory: MemoryLike

            private var uiImage: UIImage? {
                guard let data = memory.imageData else { return nil }
                return UIImage(data: data)
            }

            private var imageAspectRatio: CGFloat {
                guard let image = uiImage else { return 1 }
                return image.size.width > 0 ? image.size.height / image.size.width : 1
            }

            var body: some View {
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        if let image = uiImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.width * imageAspectRatio)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: geo.size.width, height: geo.size.width)
                        }
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.75), .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        VStack(alignment: .leading, spacing: 2) {
                            Text(memory.title ?? "")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding([.horizontal, .bottom], 8)
                    }
                    .frame(height: geo.size.width * imageAspectRatio)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12, style: .continuous)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

#Preview {
    let mocks: [MockMemory] = [
        MockMemory(title: "Sunset", color: .systemOrange, size: CGSize(width: 200, height: 300)),
        MockMemory(title: "Forest", color: .systemGreen, size: CGSize(width: 200, height: 250)),
        MockMemory(title: "Mountain", color: .systemBlue, size: CGSize(width: 200, height: 280)),
        MockMemory(title: "City", color: .systemPurple, size: CGSize(width: 200, height: 220)),
        MockMemory(title: "Beach", color: .systemTeal, size: CGSize(width: 200, height: 320))
    ]
    MasonryGridForPreview(memories: mocks.map { $0.toMemoryLike })
}
#endif
