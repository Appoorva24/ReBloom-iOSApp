import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Background gradient matching existing app style
            LinearGradient(
                colors: [Color.motherBgTop, Color.motherBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo area
                VStack(spacing: 16) {
                    Text("🌸")
                        .font(.system(size: 72))
                        .scaleEffect(appeared ? 1.0 : 0.5)
                        .opacity(appeared ? 1.0 : 0.0)
                    
                    Text("ReBloom")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.motherPrimary, .motherSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(appeared ? 1.0 : 0.0)
                    
                    Text("Your postpartum journey,\ntogether.")
                        .font(.title3.weight(.medium))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextBody)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1.0 : 0.0)
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                // Sign in with Apple button
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        authManager.handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Text("Sign in to sync your data across devices\nand connect with your partner.")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextBody.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                    
                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
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
