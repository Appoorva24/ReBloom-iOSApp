import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var vm = ProfileViewModel()
    @State private var showConnectionSheet = false
    @State private var selectedItem: PhotosPickerItem?
    @Environment(ConnectionManager.self) private var connectionManager

    var body: some View {
        NavigationStack {
            List {
                
                Section {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let urlString = vm.profileImageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: vm.profile?.role == "husband"
                                                    ? [.partnerPrimary, .partnerSecondary]
                                                    : [.motherPrimary, .motherSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            Text(vm.profile?.role == "husband" ? "💙" : "🌸")
                                                .font(.title)
                                        )
                                }
                                
                                if vm.isUploadingImage {
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .frame(width: 64, height: 64)
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    await vm.uploadProfileImage(data, modelContext: modelContext, connectionManager: connectionManager)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if vm.isEditing {
                                TextField("Your name", text: $vm.editName)
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.rounded)
                            } else {
                                Text(vm.profile?.name ?? "")
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.rounded)
                            }
                            Text(vm.profile?.role == "husband" ? "Partner" : "Mom")
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                
                Section("Baby") {
                    if vm.isEditing {
                        LabeledContent {
                            TextField("Baby's name", text: $vm.editBabyName)
                                .fontDesign(.rounded)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                        LabeledContent {
                            DatePicker("", selection: $vm.editBabyBirthDate, displayedComponents: .date)
                                .labelsHidden()
                        } label: {
                            Text("Birthday")
                                .fontDesign(.rounded)
                        }
                    } else {
                        LabeledContent {
                            Text(vm.profile?.babyName ?? "")
                                .fontDesign(.rounded)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                        LabeledContent {
                            Text(vm.profile?.babyBirthDate ?? Date(), style: .date)
                                .fontDesign(.rounded)
                        } label: {
                            Text("Birthday")
                                .fontDesign(.rounded)
                        }
                    }
                    LabeledContent {
                        Text("Week \(vm.profile?.weeksPostpartum ?? 1)")
                            .fontDesign(.rounded)
                            .foregroundStyle(vm.profile?.role == "husband" ? Color.partnerPrimary : Color.motherPrimary)
                    } label: {
                        Text("Postpartum")
                            .fontDesign(.rounded)
                    }
                }

                
                Section("Partner") {
                    if vm.isEditing {
                        LabeledContent {
                            TextField("Partner's name", text: $vm.editPartnerName)
                                .fontDesign(.rounded)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                    } else {
                        LabeledContent {
                            Text(vm.profile?.partnerName ?? "")
                                .fontDesign(.rounded)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                    }
                }

                // Connection
                Section("Connection") {
                    Button {
                        showConnectionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundStyle(Color.partnerPrimary)
                            Text("Partner Connection")
                                .fontDesign(.rounded)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                
                Section {
                    Button(role: .destructive) {
                        vm.showResetConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset ReBloom")
                                .fontDesign(.rounded)
                        }
                    }
                    .confirmationDialog(
                        "Reset ReBloom?",
                        isPresented: $vm.showResetConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Reset Everything", role: .destructive) {
                            vm.resetApp(modelContext: modelContext) {
                                onboardingDone = false
                                dismiss()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will delete all your data and restart onboarding.")
                            .fontDesign(.rounded)
                    }
                }
            }
            .navigationTitle("Profile")
            .onAppear { 
                vm.load(modelContext: modelContext)
                Task {
                    await vm.loadProfileImageFromSupabase(connectionManager: connectionManager)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if vm.isEditing {
                        Button("Cancel") {
                            vm.isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            vm.loadProfileForEditing()
                            vm.isEditing = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if vm.isEditing {
                        Button("Done") {
                            vm.saveProfile(modelContext: modelContext)
                            vm.isEditing = false
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showConnectionSheet) {
            ConnectionView()
        }
    }
}
