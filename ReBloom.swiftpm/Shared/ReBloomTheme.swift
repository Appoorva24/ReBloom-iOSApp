import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Mother Palette
extension Color {
    static let motherPrimary = Color(hex: "FF6B9D")
    static let motherSecondary = Color(hex: "FF8C69")
    static let motherGold = Color(hex: "FFD93D")
    
    static let motherTextHeading = Color(hex: "4A1942")
    static let motherTextBody = Color(hex: "7B5E7B")
    
    static let motherBgTop = Color(hex: "FFF0F5")
    static let motherBgBottom = Color(hex: "FFF8F0")
    
    static let navIconInactive = Color(hex: "C4A0A8")
    
    // Aliases used in HomeDashboardView redesign
    static let motherRose = motherPrimary
    static let motherPeach = motherSecondary
    static let motherDeepRose = Color(hex: "E8457A")
    static let motherLavender = Color(hex: "C4A0D0")
}

// MARK: - Partner Palette
extension Color {
    static let partnerBackground = Color(hex: "D6E8F5")
    static let partnerBgTop      = Color(hex: "D6E8F5")   // medium steel blue
    static let partnerBgBottom   = Color(hex: "EAF3FB")   // lighter at bottom
    static let partnerPrimary = Color(hex: "5B9BD5")
    static let partnerSecondary = Color(hex: "93D0E8")
    static let partnerAmber = Color(hex: "FFCA7A")
    static let partnerSuccess = Color(hex: "6DC9A0")
    static let partnerTextMuted = Color(hex: "7A9AB8")

    // Extended blue palette for partner UI
    static let partnerDeep  = Color(hex: "3A7BD5")   // darker blue for headings/accents
    static let partnerLight = Color(hex: "D0E4F7")   // pale blue for backgrounds
    static let partnerIce   = Color(hex: "EAF1FB")   // very light blue tint
    static let partnerNavy  = Color(hex: "2C5282")   // dark navy for strong text
}

// MARK: - Mother Glass Card
struct MotherGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.motherPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Partner Native Card
struct PartnerNativeCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.partnerPrimary.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Card Appear Modifier
struct CardAppearModifier: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(duration: 0.5, bounce: 0.3).delay(Double(index) * 0.1),
                value: appeared
            )
    }
}

extension View {
    func cardAppear(index: Int, appeared: Bool) -> some View {
        modifier(CardAppearModifier(index: index, appeared: appeared))
    }
}

// MARK: - Burst Particles
struct BurstParticles: View {
    @State private var animate = false
    let colors: [Color]

    init(colors: [Color] = [.motherPrimary, .motherSecondary, .motherGold]) {
        self.colors = colors
    }

    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count].opacity(0.7))
                    .frame(width: CGFloat.random(in: 6...14), height: CGFloat.random(in: 6...14))
                    .offset(
                        x: animate ? CGFloat.random(in: -120...120) : 0,
                        y: animate ? CGFloat.random(in: -120...120) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 1.5 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animate = true
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    @State private var show = true

    var body: some View {
        if show {
            Text(message)
                .font(.subheadline.weight(.medium))
                .fontDesign(.rounded)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            show = false
                        }
                    }
                }
        }
    }
}

// MARK: - Floating Orb
struct FloatingOrb: View {
    let color: Color
    let size: CGFloat
    @State private var offset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(color.opacity(0.25))
            .frame(width: size, height: size)
            .blur(radius: 60)
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 6...10))
                    .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -40...40),
                        height: CGFloat.random(in: -40...40)
                    )
                }
            }
    }
}

// MARK: - Pulsing Modifier
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 0.95)
            .opacity(isPulsing ? 1.0 : 0.85)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

extension View {
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
}

// MARK: - Heart Shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Start at bottom tip
        path.move(to: CGPoint(x: w * 0.5, y: h))

        // Left side curve up to the left bump
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.25),
            control1: CGPoint(x: w * 0.35, y: h * 0.8),
            control2: CGPoint(x: 0, y: h * 0.55)
        )

        // Left bump arc to the center dip
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.2),
            control1: CGPoint(x: 0, y: h * -0.05),
            control2: CGPoint(x: w * 0.35, y: h * 0.1)
        )

        // Right bump arc from center dip
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.25),
            control1: CGPoint(x: w * 0.65, y: h * 0.1),
            control2: CGPoint(x: w, y: h * -0.05)
        )

        // Right side curve back to bottom tip
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w, y: h * 0.55),
            control2: CGPoint(x: w * 0.65, y: h * 0.8)
        )

        path.closeSubpath()
        return path
    }
}
