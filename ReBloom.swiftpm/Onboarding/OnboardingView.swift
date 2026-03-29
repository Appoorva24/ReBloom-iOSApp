import SwiftUI
import SwiftData

struct WelcomeLogoView: View {
    @State private var appeared = true
    @State private var pulse    = false
    @State private var shimmer  = false

    var body: some View {
        ZStack {
            
            Circle()
                .fill(RadialGradient(
                    colors: [Color.motherPrimary.opacity(0.18), Color.motherPrimary.opacity(0.06), Color.clear],
                    center: .center, startRadius: 30, endRadius: 130
                ))
                .frame(width: 260, height: 260)
                .scaleEffect(pulse ? 1.06 : 0.96)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)

           
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.motherPrimary.opacity(0.2), Color.motherSecondary.opacity(0.1), Color.clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 180, height: 180)
                .scaleEffect(pulse ? 1.04 : 0.98)
                .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: pulse)

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1.0 : 0)
                .animation(.spring(duration: 0.8, bounce: 0.4), value: appeared)
        }
        .frame(width: 260, height: 260)
        .onAppear {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { pulse = true }
        }
    }
}


struct FeatureRow: View {
    let systemIcon: String
    let title: String
    let subtitle: String
    let color: Color
    let index: Int
    @State private var appeared = true

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(
                        colors: [color, color.opacity(0.75)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 46, height: 46)
                Image(systemName: systemIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: color.opacity(0.10), radius: 6, x: 0, y: 2)
        .offset(x: appeared ? 0 : 36)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.3).delay(Double(index) * 0.10)) {

            }
        }
    }
}


struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingDone") private var onboardingDone = false

    @State private var path: [Int]       = []
    @State private var motherName        = ""
    @State private var partnerName       = ""
    @State private var babyName          = ""
    @State private var babyBirthDate     = Date()
    @State private var animateGradient   = false

    private let accentColor = Color.motherPrimary

   
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                backgroundView.ignoresSafeArea()
                welcomeStep
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Int.self) { step in
                ZStack {
                    backgroundView.ignoresSafeArea()
                    switch step {
                    case 1: dualInterfaceStep
                    case 2: motherFeaturesStep
                    case 3: partnerFeaturesStep
                    case 4: detailsFormStep
                    case 5: enterAppStep
                    default: EmptyView()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            ForEach(1..<6, id: \.self) { i in
                                Capsule()
                                    .fill(i <= step ? accentColor : Color.secondary.opacity(0.2))
                                    .frame(width: i == step ? 22 : 8, height: 8)
                            }
                        }
                    }
                }
            }
        }
        .tint(accentColor)
    }

   
    private var backgroundView: some View {
        LinearGradient(
            colors: [.motherBgTop, Color.motherPrimary.opacity(0.14), .motherBgBottom],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint:   animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }

 
    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            WelcomeLogoView()

            Spacer().frame(height: 28)

            // App name
            Text("ReBloom")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .tracking(-0.5)
                .foregroundStyle(LinearGradient(
                    colors: [Color.motherDeepRose, Color.motherPrimary, Color.motherSecondary],
                    startPoint: .leading, endPoint: .trailing
                ))

            Spacer().frame(height: 15)

            // Tagline
            Text("Postpartum healing for mothers, guidance for partners, together helping her ReBloom.")
                .font(.title3.weight(.medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextHeading.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            // CTA Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                path.append(1)
            } label: {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.headline).fontDesign(.rounded)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(LinearGradient(
                    colors: [Color.motherDeepRose, Color.motherPrimary],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 44)
        }
        .padding(.horizontal, 28)
    }


    private var dualInterfaceStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Visual — two overlapping circles representing both roles
            ZStack {
                // Outer glow
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.motherPrimary.opacity(0.12), Color.clear],
                        center: .center, startRadius: 20, endRadius: 120
                    ))
                    .frame(width: 240, height: 240)

                // Mother circle
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.motherPrimary.opacity(0.18), Color.motherPrimary.opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 110, height: 110)
                    .offset(x: -30)
                    .overlay(
                        Image(systemName: "figure.and.child.holdinghands")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(Color.motherPrimary)
                            .offset(x: -30)
                    )

                // Partner circle
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.partnerPrimary.opacity(0.18), Color.partnerPrimary.opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 110, height: 110)
                    .offset(x: 30)
                    .overlay(
                        Image(systemName: "person.fill.checkmark")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color.partnerPrimary)
                            .offset(x: 30)
                    )

                // Heart in the overlap
                Image(systemName: "heart.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.motherPrimary, Color.partnerPrimary],
                        startPoint: .leading, endPoint: .trailing
                    ))
            }

            Spacer().frame(height: 28)

            // Title
            Text("Healing Together")
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.motherTextHeading)

            Spacer().frame(height: 10)

            // Subtitle
            Text("ReBloom supports both mothers and their partners during the postpartum journey.")
                .font(.body.weight(.medium))
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Spacer().frame(height: 24)

            Spacer()

            // Continue button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                path.append(2)
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.headline).fontDesign(.rounded)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(LinearGradient(
                    colors: [Color.motherDeepRose, Color.motherPrimary],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 44)
        }
        .padding(.horizontal, 24)
    }

  
    private var motherFeaturesStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.motherPrimary.opacity(0.10))
                        .frame(width: 68, height: 68)
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.motherPrimary)
                }

                Text("For Mother")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.motherTextHeading)

                Text("Your postpartum recovery companion")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 24)

            // Tab-based feature cards
            VStack(spacing: 10) {
                FeatureRow(
                    systemIcon: "heart.fill",
                    title: "Us",
                    subtitle: "Track your mood, share heart notes with your partner, and stay connected.",
                    color: Color.motherPrimary,
                    index: 0
                )
                FeatureRow(
                    systemIcon: "photo.on.rectangle.angled",
                    title: "Memories",
                    subtitle: "Save and share your baby's precious first moments together.",
                    color: Color(hex: "FF8C69"),
                    index: 1
                )
                FeatureRow(
                    systemIcon: "figure.mind.and.body",
                    title: "Heal",
                    subtitle: "Guided recovery exercises, breathing support, and daily Bloom progress.",
                    color: Color(hex: "6DC9A0"),
                    index: 2
                )
            }
            .padding(.horizontal, 4)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                path.append(3)
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.headline).fontDesign(.rounded)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(LinearGradient(
                    colors: [Color.motherPrimary, Color.motherSecondary],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.32), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 44)
        }
        .padding(.horizontal, 24)
    }

  
    private var partnerFeaturesStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.partnerPrimary.opacity(0.10))
                        .frame(width: 68, height: 68)
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color.partnerPrimary)
                }

                Text("For Partner")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.motherTextHeading)

                Text("Be her strength through postpartum")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 24)

            // Tab-based feature cards
            VStack(spacing: 10) {
                FeatureRow(
                    systemIcon: "heart.fill",
                    title: "Us",
                    subtitle: "See her mood, complete daily support missions, and send encouragement.",
                    color: Color.partnerPrimary,
                    index: 0
                )
                FeatureRow(
                    systemIcon: "photo.on.rectangle.angled",
                    title: "Memories",
                    subtitle: "Capture and share your baby's milestones and special moments.",
                    color: Color.partnerDeep,
                    index: 1
                )
                FeatureRow(
                    systemIcon: "book.fill",
                    title: "Learn",
                    subtitle: "Understand her postpartum journey and learn how to support recovery.",
                    color: Color(hex: "6366F1"),
                    index: 2
                )
            }
            .padding(.horizontal, 4)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                path.append(4)
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.headline).fontDesign(.rounded)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(LinearGradient(
                    colors: [Color.motherPrimary, Color.motherSecondary],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.32), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 44)
        }
        .padding(.horizontal, 24)
    }


    private var detailsFormStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.motherPrimary.opacity(0.10))
                        .frame(width: 60, height: 60)
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.motherPrimary)
                }
                .padding(.bottom, 4)

                Text("A little about you")
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                Text("We'll use this to personalise your experience")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Spacer().frame(height: 28)

            VStack(spacing: 12) {
                customTextField(
                    label: "Mother's name",
                    placeholder: "e.g. Sarah",
                    text: $motherName,
                    icon: "figure.and.child.holdinghands"
                )
                customTextField(
                    label: "Partner's name",
                    placeholder: "e.g. James",
                    text: $partnerName,
                    icon: "person.fill.checkmark"
                )
                customTextField(
                    label: "Baby's name",
                    placeholder: "e.g. Lily (optional)",
                    text: $babyName,
                    icon: "star.fill"
                )

                
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.motherPrimary.opacity(0.7))
                        Text("Baby's birthday")
                            .font(.caption.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    DatePicker("", selection: $babyBirthDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(Color.motherPrimary)
                        .labelsHidden()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.07), radius: 6, x: 0, y: 2)
            }

            Spacer()

            if !motherName.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    path.append(5)
                } label: {
                    HStack(spacing: 8) {
                        Text("Almost There")
                            .font(.headline).fontDesign(.rounded)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(LinearGradient(
                        colors: [Color.motherPrimary, Color.motherSecondary],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.motherPrimary.opacity(0.32), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)
                    .frame(height: 54)
            }

            Spacer().frame(height: 44)
        }
        .padding(.horizontal, 24)
    }

    private func customTextField(label: String, placeholder: String,
                                 text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.motherPrimary.opacity(0.7))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: text)
                    .font(.body).fontDesign(.rounded)
                    .textFieldStyle(.plain)
                    .tint(Color.motherPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.07), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(text.wrappedValue.isEmpty ? Color.clear : Color.motherPrimary.opacity(0.28), lineWidth: 1.5)
        )
    }


    private var enterAppStep: some View {
        VStack(spacing: 0) {
            Spacer()

     
            ZStack {
       
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.motherPrimary.opacity(0.15), Color.motherSecondary.opacity(0.08), Color.clear],
                        center: .center, startRadius: 20, endRadius: 120
                    ))
                    .frame(width: 240, height: 240)

            
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.motherPrimary.opacity(0.12), Color.motherSecondary.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.motherDeepRose, Color.motherPrimary, Color.motherSecondary],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                }
            }

            Spacer().frame(height: 28)

            VStack(spacing: 8) {
                Text("You're all set!")
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)

                Text("Your ReBloom journey begins now.\nHeal, connect, and grow — together.")
                    .font(.body.weight(.medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Spacer().frame(height: 28)

     
            VStack(spacing: 10) {
                disclaimerRow(
                    icon: "stethoscope",
                    text: "Always consult your healthcare provider for medical concerns.",
                    color: Color.motherPrimary
                )
                disclaimerRow(
                    icon: "leaf.fill",
                    text: "ReBloom is a wellness companion — it does not replace professional care.",
                    color: Color.motherPrimary
                )
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                saveProfile()
            } label: {
                HStack(spacing: 8) {
                    Text("Begin My Journey")
                        .font(.headline).fontDesign(.rounded)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(LinearGradient(
                    colors: [Color.motherDeepRose, Color.motherPrimary],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.36), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 44)
        }
        .padding(.horizontal, 24)
    }

    private func disclaimerRow(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: color.opacity(0.07), radius: 5, x: 0, y: 2)
    }

    private func saveProfile() {
        let profile = UserProfile(
            name: motherName,
            role: "mother",
            babyName: babyName,
            babyBirthDate: babyBirthDate,
            partnerName: partnerName,
            onboardingComplete: true,
            firstLaunchDate: Date()
        )
        modelContext.insert(profile)
        try? modelContext.save()
        onboardingDone = true
    }
}
