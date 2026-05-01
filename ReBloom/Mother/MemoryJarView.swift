import SwiftUI
import SwiftData
import PhotosUI

struct MemoryJarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = MemoryJarViewModel()

    @State private var appeared = true

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.motherBgTop, .motherBgBottom],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                FloatingOrb(color: .motherSecondary, size: 200).position(x: 60,  y: 180)
                FloatingOrb(color: .motherLavender,  size: 180).position(x: 320, y: 500)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        introBanner
                            .cardAppear(index: 0, appeared: appeared)

                        if vm.memories.isEmpty {
                            emptyState
                                .cardAppear(index: 1, appeared: appeared)
                        } else {
                            memoriesGrid
                                .cardAppear(index: 1, appeared: appeared)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Memory Jar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        vm.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.motherRose)
                    }
                }
            }
            .sheet(isPresented: $vm.showAddSheet) {
                AddMemorySheet(partnerName: vm.profile?.partnerName ?? "Partner") { memory in
                    vm.saveMemory(memory, modelContext: modelContext)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { vm.showToast = false }
                }
            }
            .fullScreenCover(item: $vm.selectedMemory) { memory in
                MemoryDetailView(
                    memory: memory,
                    partnerName: vm.profile?.partnerName ?? "Partner"
                ) {
                    vm.shareToast()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { vm.showToast = false }
                }
            }
            .overlay(alignment: .bottom) {
                if vm.showToast {
                    ToastView(message: vm.toastMessage)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.4), value: vm.showToast)
            .onAppear {
                vm.load(modelContext: modelContext)
            }
        }
    }

    
    private var introBanner: some View {
        let partnerName = vm.profile?.partnerName ?? "your partner"

        return HStack(alignment: .top, spacing: 0) {
            Text("Share special moments with \(partnerName)")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .italic()
                .foregroundStyle(Color.motherTextHeading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 2)
    }

    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🌸")
                .font(.system(size: 44))
                .padding(.top, 24)

            VStack(spacing: 6) {
                Text("No memories yet")
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                Text("First smile, tiny yawn, sleepy cuddles —\nall the little things worth keeping 🌸")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                vm.showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 16))
                    Text("Add First Memory")
                        .font(.subheadline.weight(.bold)).fontDesign(.rounded)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(colors: [.motherRose, .motherDeepRose], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: Color.motherRose.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.08), radius: 8, x: 0, y: 3)
        .padding(.horizontal, 16)
    }

    
    private var memoriesGrid: some View {
        let grouped = vm.groupedByDate(vm.memories)
        let sortedKeys = grouped.keys.sorted {
            let fmt = DateFormatter(); fmt.dateFormat = "d MMMM yyyy"
            return (fmt.date(from: $0) ?? Date()) > (fmt.date(from: $1) ?? Date())
        }
        return VStack(spacing: 28) {
            ForEach(sortedKeys, id: \.self) { dateKey in
                if let dayMemories = grouped[dateKey] {
                    VStack(alignment: .leading, spacing: 14) {
                        // Date pill header
                        HStack(spacing: 8) {
                            Text(dateKey)
                                .font(.caption.weight(.bold))
                                .fontDesign(.rounded)
                                .kerning(0.6)
                                .foregroundStyle(Color.motherRose)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.motherRose.opacity(0.1))
                                .clipShape(Capsule())
                            Rectangle()
                                .fill(Color.motherRose.opacity(0.12))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)

                    
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(dayMemories) { memory in
                                MemoryCard(memory: memory) {
                                    vm.selectedMemory = memory
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}


struct MemoryCard: View {
    let memory: Memory
    let onTap: () -> Void

    private let cardHeight: CGFloat = 200

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Photo layer
                if let uiImage = UIImage(data: memory.imageData) {
                    GeometryReader { geo in
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: cardHeight)
                            .clipped()
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.motherRose.opacity(0.12), Color.motherLavender.opacity(0.12)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Info overlay
                VStack(alignment: .leading, spacing: 4) {
                    if memory.isSharedWithPartner {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill").font(.system(size: 9))
                                .foregroundStyle(memory.sharedBy == "husband" ? Color.partnerPrimary : Color.motherRose)
                            Text("Shared").font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    if !memory.title.isEmpty {
                        Text(memory.title)
                            .font(.subheadline.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                }
                .padding(12)

                // New dot badge
                if memory.isNewForPartner {
                    Circle()
                        .fill(Color.motherRose)
                        .frame(width: 9, height: 9)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}


struct AddMemorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let partnerName: String
    let onSave: (Memory) -> Void

    @State private var title            = ""
    @State private var caption          = ""
    @State private var selectedImage: UIImage? = nil
    @State private var shareWithPartner = true
    @State private var showSourcePicker = false
    @State private var showCamera       = false
    @State private var showGallery      = false
    @State private var selectedItem: PhotosPickerItem?

    var canSave: Bool { !title.isEmpty && selectedImage != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.motherBgTop, .motherBgBottom],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        // Photo picker area
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.motherRose.opacity(0.05))
                                .frame(height: 220)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 2, dash: [8, 5])
                                        )
                                        .foregroundStyle(selectedImage == nil ? Color.motherRose.opacity(0.25) : Color.clear)
                                )

                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 220)
                                    .background(Color.black.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                                
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button { showSourcePicker = true } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text("Change")
                                                    .font(.caption.weight(.semibold))
                                                    .fontDesign(.rounded)
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(.black.opacity(0.45))
                                            .clipShape(Capsule())
                                        }
                                        .padding(12)
                                    }
                                }
                            } else {
                                Button { showSourcePicker = true } label: {
                                    VStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.motherRose.opacity(0.1))
                                                .frame(width: 60, height: 60)
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(Color.motherRose)
                                        }
                                        VStack(spacing: 4) {
                                            Text("Add a Photo")
                                                .font(.subheadline.weight(.bold))
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.motherRose)
                                            Text("Camera or Gallery")
                                                .font(.caption)
                                                .fontDesign(.rounded)
                                                .foregroundStyle(Color.motherRose.opacity(0.6))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .confirmationDialog("Add Photo", isPresented: $showSourcePicker, titleVisibility: .visible) {
                            Button("Take Photo") { showCamera = true }
                            Button("Choose from Gallery") { showGallery = true }
                            Button("Cancel", role: .cancel) {}
                        }
                        .fullScreenCover(isPresented: $showCamera) {
                            CameraPickerView(image: $selectedImage)
                                .ignoresSafeArea()
                        }
                        .photosPicker(isPresented: $showGallery, selection: $selectedItem, matching: .images)
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run { selectedImage = image }
                                }
                            }
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 7) {
                            Text("MEMORY TITLE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .kerning(1.4)
                                .foregroundStyle(Color.motherRose.opacity(0.7))
                            TextField("e.g. First smile 🌸", text: $title)
                                .font(.body).fontDesign(.rounded)
                                .padding(13)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(title.isEmpty ? Color.motherRose.opacity(0.15) : Color.motherRose.opacity(0.4), lineWidth: 1.5)
                                )
                        }

                        // Caption
                        VStack(alignment: .leading, spacing: 7) {
                            Text("ADD A NOTE  (OPTIONAL)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .kerning(1.4)
                                .foregroundStyle(Color.motherRose.opacity(0.7))
                            ZStack(alignment: .topLeading) {
                                if caption.isEmpty {
                                    Text("Write something about this moment…")
                                        .font(.body).fontDesign(.rounded)
                                        .foregroundStyle(Color.secondary.opacity(0.5))
                                        .padding(.top, 15).padding(.leading, 15)
                                        .allowsHitTesting(false)
                                }
                                TextEditor(text: $caption)
                                    .font(.body).fontDesign(.rounded)
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                                    .padding(9)
                            }
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(Color.motherRose.opacity(0.15), lineWidth: 1.5)
                            )
                        }

                        // Share toggle
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.motherRose.opacity(0.1))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.motherRose)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Share with \(partnerName)")
                                    .font(.subheadline.weight(.semibold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(Color.motherTextHeading)
                                Text("He'll see this in his Memory Jar")
                                    .font(.caption).fontDesign(.rounded)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $shareWithPartner)
                                .tint(Color.motherRose).labelsHidden()
                        }
                        .padding(13)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .shadow(color: Color.motherPrimary.opacity(0.05), radius: 4, x: 0, y: 2)

                        // Save button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            guard let image = selectedImage,
                                  let data = image.jpegData(compressionQuality: 0.8) else { return }
                            let memory = Memory(
                                title: title,
                                caption: caption,
                                imageData: data,
                                isSharedWithPartner: shareWithPartner,
                                isNewForPartner: shareWithPartner,
                                sharedBy: "wife"
                            )
                            onSave(memory)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                                Text("Save Memory")
                                    .font(.subheadline.weight(.bold)).fontDesign(.rounded)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                canSave
                                ? AnyShapeStyle(LinearGradient(colors: [.motherRose, .motherDeepRose], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.motherRose.opacity(0.3))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .shadow(color: canSave ? Color.motherRose.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .fontDesign(.rounded).foregroundStyle(.secondary)
                }
            }
        }
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }
}


struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}




struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let memory: Memory
    let partnerName: String
    let onShare: () -> Void

    @State private var showDeleteConfirm = false
    @State private var showBars = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let uiImage = UIImage(data: memory.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) { showBars.toggle() }
                        }
                }

                if showBars {
                    VStack {
                        Spacer()

                        VStack(alignment: .leading, spacing: 8) {
                            Text(memory.title)
                                .font(.title3.weight(.bold))
                                .fontDesign(.rounded)
                                .foregroundStyle(.white)

                            Text(memory.date.formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.white.opacity(0.7))

                            if !memory.caption.isEmpty {
                                Text(memory.caption)
                                    .font(.subheadline)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineSpacing(3)
                            }

                            if memory.isSharedWithPartner {
                                HStack(spacing: 5) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 11))
                                    Text("Shared with \(partnerName)")
                                        .font(.caption.weight(.semibold))
                                        .fontDesign(.rounded)
                                }
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .padding(.bottom, 50)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.65)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .bottomBar)
            .toolbar(showBars ? .visible : .hidden, for: .navigationBar)
            .toolbar(showBars ? .visible : .hidden, for: .bottomBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.white)
                    }
                }
            }
            .confirmationDialog("Delete this memory?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(memory)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}


extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
