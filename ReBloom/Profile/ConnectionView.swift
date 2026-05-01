import SwiftUI

struct ConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager
    @Environment(ConnectionManager.self) private var connectionManager
    
    @State private var partnerCode = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showDisconnectConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.motherBgTop, Color.motherBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Your invite code card
                        myCodeCard
                        
                        // Connection status or connect form
                        if connectionManager.connectionStatus == .accepted {
                            connectedCard
                        } else {
                            connectCard
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Partner Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherPrimary)
                }
            }
            .alert("Disconnect Partner?", isPresented: $showDisconnectConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Disconnect", role: .destructive) {
                    Task {
                        try? await connectionManager.disconnect()
                    }
                }
            } message: {
                Text("This will remove the connection with your partner. You can reconnect later.")
            }
        }
    }
    
    // MARK: - My Code Card
    private var myCodeCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundStyle(Color.motherPrimary)
                Text("Your Invite Code")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                Spacer()
            }
            
            Text(connectionManager.inviteCode ?? "------")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .kerning(6)
                .foregroundStyle(Color.motherPrimary)
                .padding(.vertical, 12)
            
            Text("Share this code with your partner so they can connect with you.")
                .font(.caption)
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextBody)
                .multilineTextAlignment(.center)
            
            Button {
                UIPasteboard.general.string = connectionManager.inviteCode
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                    Text("Copy Code")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                }
                .foregroundStyle(Color.motherPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.motherPrimary.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Connect Card
    private var connectCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                    .font(.title3)
                    .foregroundStyle(Color.partnerPrimary)
                Text("Connect with Partner")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                Spacer()
            }
            
            TextField("Enter partner's code", text: $partnerCode)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .kerning(4)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .padding(14)
                .background(Color(hex: "F5F5F5"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.red)
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isConnecting = true
                errorMessage = nil
                
                Task {
                    do {
                        try await connectionManager.sendConnectionRequest(partnerInviteCode: partnerCode)
                        await MainActor.run { isConnecting = false }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            isConnecting = false
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isConnecting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "heart.fill")
                        Text("Connect")
                    }
                }
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.motherPrimary, .motherSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(partnerCode.count < 6 || isConnecting)
            .opacity(partnerCode.count < 6 ? 0.6 : 1.0)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.partnerPrimary.opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Connected Card
    private var connectedCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "heart.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.partnerSuccess)
                Text("Connected!")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                Spacer()
            }
            
            Text("You and your partner are connected. Memories, moods, and missions will sync automatically.")
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextBody)
                .lineSpacing(3)
            
            Button {
                showDisconnectConfirm = true
            } label: {
                Text("Disconnect")
                    .font(.subheadline.weight(.medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.partnerSuccess.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
