import SwiftUI

struct LearnArticle: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let keyPoints: [String]
    let rememberNote: String
}

private let learnArticles: [LearnArticle] = [
    LearnArticle(
        icon: "brain.head.profile",
        title: "Her Emotions",
        subtitle: "Understanding what she's going through",
        gradientColors: [Color(hex: "3A7BD5"), Color(hex: "5B9BD5")],
        keyPoints: [
            "Hormones drop massively in 48 hours after birth — mood swings and tearfulness are normal",
            "\"Baby blues\" affect 80% of mothers and usually pass in 2 weeks",
            "Postpartum depression affects 1 in 7 women — persistent sadness, difficulty bonding, or intrusive thoughts are warning signs",
            "Your role: be present, listen without judgment, validate her feelings — don't try to fix everything",
            "If symptoms persist beyond 2 weeks, encourage her to talk to her doctor"
        ],
        rememberNote: "You can't fix her hormones, but you can make her feel seen."
    ),
    LearnArticle(
        icon: "moon.zzz.fill",
        title: "Sleep & Rest",
        subtitle: "Why rest is medicine for recovery",
        gradientColors: [Color(hex: "2C5282"), Color(hex: "5B9BD5")],
        keyPoints: [
            "New mothers rarely get more than 2–3 hours of unbroken sleep — this affects mood, healing, and milk production",
            "New parents lose an average of 44 days of sleep in the first year",
            "Take at least one night feeding — create a \"shift system\" to split the night",
            "On weekends, let her sleep in without asking. Just take the baby",
            "Even 90 extra minutes of uninterrupted sleep can be transformative for her"
        ],
        rememberNote: "Every hour of sleep you give her is medicine. Guard her rest."
    ),
    LearnArticle(
        icon: "heart.circle.fill",
        title: "Being Present",
        subtitle: "Small acts of attention that matter most",
        gradientColors: [Color(hex: "5B9BD5"), Color(hex: "93D0E8")],
        keyPoints: [
            "Put your phone down when she talks — full attention is the most powerful gift",
            "Ask \"How are you really doing?\" and wait for the honest answer",
            "When she says \"I'm exhausted,\" don't fix it — say \"What would help right now?\"",
            "Physical micro-moments matter: a hug, holding her hand, rubbing her shoulders",
            "Her body did something extraordinary — patience and steady presence is love"
        ],
        rememberNote: "Don't fix — just be present. Your steadiness is her foundation."
    ),
    LearnArticle(
        icon: "figure.2.and.child.holdinghands",
        title: "Fourth Trimester",
        subtitle: "The critical first 3 months explained",
        gradientColors: [Color(hex: "3A7BD5"), Color(hex: "93D0E8")],
        keyPoints: [
            "Newborns crave swaddling, rocking, and contact — the outside world is a sensory shock after the womb",
            "Her body is healing from delivery — uterus shrinking, hormones recalibrating, milk production ongoing",
            "Physical recovery includes: 4–6 weeks of bleeding, night sweats, hair loss, joint pain",
            "She's processing birth, establishing identity as a mother, and navigating every relationship shift",
            "How you show up now shapes your family forever"
        ],
        rememberNote: "This is temporary, but how you show up now lasts forever."
    ),
    LearnArticle(
        icon: "fork.knife",
        title: "Nourishment",
        subtitle: "Making sure she's eating and hydrated",
        gradientColors: [Color(hex: "2C5282"), Color(hex: "3A7BD5")],
        keyPoints: [
            "Breastfeeding needs 300–500 extra calories/day — she'll often forget to eat",
            "Keep a full water bottle near wherever she nurses — dehydration affects milk supply",
            "Prepare one-hand snacks: granola bars, cut fruit, trail mix, cheese sticks",
            "Meal prep on weekends — big batch soups, chili, or pasta sauce that reheats easily",
            "If she says \"I'm not hungry,\" gently leave food nearby — she'll usually eat it"
        ],
        rememberNote: "She will forget to eat. Make nourishment your mission."
    )
]


struct LearnView: View {
    @State private var appeared = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background
                LinearGradient(
                    colors: [Color.partnerBgTop, Color.partnerBgBottom, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()

                FloatingOrb(color: .partnerPrimary, size: 200).position(x: 300, y: 160)
                FloatingOrb(color: .partnerSecondary, size: 150).position(x: 50, y: 500)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(Array(learnArticles.enumerated()), id: \.element.id) { index, article in
                            NavigationLink(destination: LearnArticleView(article: article)) {
                                articleHeroCard(article)
                            }
                            .buttonStyle(.plain)
                            .cardAppear(index: index, appeared: appeared)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {

            }
        }
    }

   
    private func articleHeroCard(_ article: LearnArticle) -> some View {
        ZStack(alignment: .bottomLeading) {
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: article.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

        
            Image(systemName: article.icon)
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 14)
                .padding(.trailing, 18)

            
            HStack(spacing: 14) {
                
                Image(systemName: article.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)

                    Text(article.subtitle)
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
        }
        .frame(height: 110)
        .shadow(color: article.gradientColors.first?.opacity(0.25) ?? .clear, radius: 10, x: 0, y: 4)
    }
}


struct LearnArticleView: View {
    let article: LearnArticle
    @State private var appeared = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.partnerBackground, Color(hex: "D4E8F5"), .white],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // Hero header
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: article.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        
                        Image(systemName: article.icon)
                            .font(.system(size: 100, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.12))
                            .offset(x: 60, y: -10)

                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                Image(systemName: article.icon)
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(.white)
                            }

                            Text(article.title)
                                .font(.title.weight(.bold))
                                .fontDesign(.rounded)
                                .foregroundStyle(.white)

                            Text(article.subtitle)
                                .font(.subheadline.weight(.medium))
                                .fontDesign(.rounded)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 28)
                    }
                    .frame(height: 220)

                    
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.partnerDeep)
                        Text("KEY POINTS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .kerning(1.5)
                            .foregroundStyle(Color.partnerDeep)
                    }
                    .padding(.horizontal, 4)

                    
                    VStack(spacing: 12) {
                        ForEach(Array(article.keyPoints.enumerated()), id: \.offset) { index, point in
                            keyPointCard(index: index, point: point)
                                .cardAppear(index: index, appeared: appeared)
                        }
                    }

                    
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.partnerDeep.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.partnerDeep)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remember")
                                .font(.headline.weight(.bold))
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.partnerNavy)
                            Text(article.rememberNote)
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.partnerTextMuted)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.partnerDeep.opacity(0.08), Color.partnerSecondary.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.partnerDeep.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {

        }
    }

    
    private func keyPointCard(index: Int, point: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: article.gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.partnerDeep)
            }

            Text(point)
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.partnerNavy)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.partnerPrimary.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
