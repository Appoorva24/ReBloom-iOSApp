import SwiftUI

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    
    var isMother: Bool = true
    
    @State private var appeared = false
    @State private var email = ""
    @State private var password = ""
    
    private var themePrimary: Color { isMother ? .motherPrimary : .partnerPrimary }
    private var themeSecondary: Color { isMother ? .motherSecondary : .partnerSecondary }
    private var themeBgTop: Color { isMother ? .motherBgTop : .partnerBgTop }
    private var themeBgBottom: Color { isMother ? .motherBgBottom : .partnerBgBottom }
    private var themeText: Color { isMother ? .motherTextBody : .partnerNavy }
    
    var body: some View {
        ZStack {
            // Background gradient matching existing app style
            LinearGradient(
                colors: [themeBgTop, themeBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo area
                VStack(spacing: 16) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1.0 : 0.0)
                    
                    Text("ReBloom")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themePrimary, themeSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(appeared ? 1.0 : 0.0)
                    
                    Text("Your postpartum journey,\ntogether.")
                        .font(.title3.weight(.medium))
                        .fontDesign(.rounded)
                        .foregroundStyle(themeText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1.0 : 0.0)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Email and Password Login
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .padding(.bottom, 8)
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            await authManager.signIn(email: email, password: password)
                        }
                    } label: {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            await authManager.signUp(email: email, password: password)
                        }
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundStyle(themePrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(themePrimary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    
                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }
}
