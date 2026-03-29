import SwiftUI

enum ExerciseAnimationType: String {
    case deepBreathing
    case pelvicFloorHold
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let benefit: String
    let color: Color
    let weekRange: ClosedRange<Int>
    let animationType: ExerciseAnimationType
    let steps: [String]
}

let allExercises: [Exercise] = [
    Exercise(
        name: "Deep Breathing",
        icon: "wind",
        benefit: "Calms the nervous system",
        color: .motherPrimary,
        weekRange: 1...1,
        animationType: .deepBreathing,
        steps: [
            "Lie comfortably on your back",
            "Place one hand on your abdomen",
            "Inhale slowly through your nose",
            "Hold your breath gently",
            "Exhale slowly through your mouth",
            "Relax your abdominal muscles"
        ]
    ),
    Exercise(
        name: "Pelvic Floor Hold",
        icon: "circle.hexagongrid",
        benefit: "Rebuilds core stability",
        color: .motherSecondary,
        weekRange: 1...1,
        animationType: .pelvicFloorHold,
        steps: [
            "Lie on your back with knees bent",
            "Gently engage your pelvic floor muscles",
            "Inhale before lifting",
            "Exhale and slowly lift your hips",
            "Hold for a few seconds",
            "Lower down gently and relax"
        ]
    )
]

struct ExerciseAnimationView: View {
    let type: ExerciseAnimationType
    let size: CGFloat
    var isActive: Bool = true

    @State private var animate = false

    var body: some View {
        Group {
            switch type {
            case .deepBreathing:   deepBreathingView
            case .pelvicFloorHold: pelvicFloorView
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if isActive { withAnimation { animate = true } }
        }
        .onChange(of: isActive) { _, newValue in
            withAnimation { animate = newValue }
        }
    }

   
    private var deepBreathingView: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color.motherPrimary.opacity(0.5), Color.motherPrimary.opacity(0.15)],
                    center: .center,
                    startRadius: 5,
                    endRadius: size * 0.45
                ))
                .scaleEffect(animate ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)

            Text(animate ? "Breathe Out" : "Breathe In")
                .font(.caption2.weight(.medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherPrimary)
        }
    }


    private var pelvicFloorView: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.motherSecondary.opacity(0.6), lineWidth: 2)
                    .scaleEffect(animate ? 1.0 + CGFloat(i) * 0.2 : 0.4)
                    .opacity(animate ? 0.2 : 0.8)
                    .animation(
                        .easeOut(duration: 2).repeatForever(autoreverses: false).delay(Double(i) * 0.3),
                        value: animate
                    )
            }
        }
    }
}


func exercisesForWeek(_ week: Int) -> [Exercise] {
    allExercises.filter { $0.weekRange.contains(week) }
}
