import SwiftUI
import SwiftData
import AVFoundation

struct ExerciseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = ExerciseDetailViewModel()
    let exercise: Exercise

    @State private var showDurationSheet = false

    enum ExerciseState {
        case notStarted, ready, active, paused, completed
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.motherBgTop, .motherBgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    if vm.exerciseState == .notStarted {
                        infoCard
                        howToCard
                        startButton
                    } else if exercise.animationType == .pelvicFloorHold {
                        PelvicFloorSessionView(
                            exerciseState: vm.exerciseState,
                            seconds: vm.seconds,
                            onStart: vm.startExercise,
                            onPause: vm.pauseExercise,
                            onResume: vm.resumeExercise,
                            onEnd: { vm.endExerciseFully(exerciseName: exercise.name, modelContext: modelContext) }
                        )
                    } else {
                        BreathingSessionView(
                            exerciseState: vm.exerciseState,
                            seconds: vm.seconds,
                            onStart: vm.startExercise,
                            onPause: vm.pauseExercise,
                            onResume: vm.resumeExercise,
                            onEnd: { vm.endExerciseFully(exerciseName: exercise.name, modelContext: modelContext) }
                        )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load(modelContext: modelContext) }
        .onDisappear { vm.cleanup() }
        .sheet(isPresented: $showDurationSheet) {
            durationSelectionSheet
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    
    private var infoCard: some View {
        HStack(spacing: 0) {
            infoColumn(label: "Benefit", value: exercise.benefit)
            Divider().frame(height: 40)
            infoColumn(label: "Weeks", value: "Week 1")
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func infoColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    
    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to do it")
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextHeading)

            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            LinearGradient(colors: [.motherPrimary, .motherGold],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())

                    Text(step)
                        .font(.body)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.motherPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    
    private var startButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showDurationSheet = true
        } label: {
            Text("Start Exercise")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.motherPrimary, .motherSecondary],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    
    private var durationSelectionSheet: some View {
        VStack(spacing: 24) {
            Text("Select Duration")
                .font(.title2.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextHeading)
                .padding(.top, 20)

            VStack(spacing: 16) {
                durationButton(minutes: 2)
                durationButton(minutes: 5)
                durationButton(minutes: 10)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color.motherBgTop.ignoresSafeArea())
    }

    private func durationButton(minutes: Int) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            vm.selectedDuration = minutes * 60
            showDurationSheet = false
            withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                vm.exerciseState = .ready
                vm.seconds = 0
            }
        } label: {
            Text("\(minutes) minutes")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.motherPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}


enum PelvicFloorPhase: CaseIterable {
    case lieDown, inhale, lift, hold, relax

    var duration: Int {
        switch self {
        case .lieDown: return 4
        case .inhale:  return 4
        case .lift:    return 4
        case .hold:    return 5
        case .relax:   return 4
        }
    }

    var instruction: String {
        switch self {
        case .lieDown: return "Lie down in this position."
        case .inhale:  return "Breathe in."
        case .lift:    return "Exhale and lift your hips."
        case .hold:    return "Hold."
        case .relax:   return "Lower your hips and relax."
        }
    }

    var imageName: String {
        switch self {
        case .lieDown, .inhale, .relax: return "pelvic1"
        case .lift, .hold:              return "pelvic2"
        }
    }
}


enum BreathingPhase: CaseIterable {
    case inhale, hold, exhale, relax

    var duration: Int {
        switch self {
        case .inhale: return 4
        case .hold:   return 4
        case .exhale: return 4
        case .relax:  return 3
        }
    }

    var instruction: String {
        switch self {
        case .inhale: return "Breathe in slowly."
        case .hold:   return "Hold."
        case .exhale: return "Breathe out slowly."
        case .relax:  return "Relax."
        }
    }

    var circleScale: CGFloat {
        switch self {
        case .inhale, .hold:   return 1.0
        case .exhale, .relax:  return 0.45
        }
    }
}


class VoiceGuidanceManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.interruptSpokenAudioAndMixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session for speech: \(error)")
        }
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 0.9
        if let voice = AVSpeechSynthesisVoice(language: "en-US") { utterance.voice = voice }
        synthesizer.speak(utterance)
    }

    func stopSpeaking() { synthesizer.stopSpeaking(at: .immediate) }
}

private func timerBlock(seconds: Int) -> some View {
    VStack(spacing: 4) {
        Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
            .font(.system(size: 64, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.motherTextHeading)
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.3), value: seconds)
        Text("elapsed")
            .font(.subheadline)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
}

private func phaseStrip<Phase: Hashable & CaseIterable>(
    phases: [Phase],
    current: Phase,
    completed: @escaping (Phase) -> Bool
) -> some View {
    HStack(spacing: 5) {
        ForEach(Array(phases.enumerated()), id: \.offset) { _, phase in
            let isCurrent = phase == current
            let isPast    = completed(phase)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    isCurrent
                    ? LinearGradient(colors: [.motherPrimary, .motherGold], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(
                        colors: [
                            isPast ? Color.motherPrimary.opacity(0.40) : Color.gray.opacity(0.20),
                            isPast ? Color.motherPrimary.opacity(0.40) : Color.gray.opacity(0.20)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: isCurrent ? 7 : 4)
                .animation(.spring(duration: 0.35), value: isCurrent)
        }
    }
    .padding(.horizontal, 4)
}

private func controlButtons(
    exerciseState: ExerciseDetailView.ExerciseState,
    onStartEnd: @escaping () -> Void,
    onPauseResume: @escaping () -> Void
) -> some View {
    let isRunning = exerciseState == .active || exerciseState == .paused
    let disabled  = exerciseState == .notStarted || exerciseState == .ready

    return HStack(spacing: 14) {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onStartEnd()
        } label: {
            Text(isRunning ? "End" : "Start")
                .font(.headline).fontDesign(.rounded)
                .foregroundStyle(isRunning ? Color.motherPrimary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Group {
                    if isRunning { AnyView(Color.white) }
                    else { AnyView(LinearGradient(colors: [.motherPrimary, .motherSecondary], startPoint: .leading, endPoint: .trailing)) }
                })
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isRunning ? Color.motherPrimary : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)

        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onPauseResume()
        } label: {
            Text(exerciseState == .paused ? "Resume" : "Pause")
                .font(.headline).fontDesign(.rounded)
                .foregroundStyle(disabled ? Color.gray : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Group {
                    if disabled { AnyView(Color.gray.opacity(0.25)) }
                    else { AnyView(LinearGradient(colors: [.motherPrimary, .motherSecondary], startPoint: .leading, endPoint: .trailing)) }
                })
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

private func instructionLabel(
    exerciseState: ExerciseDetailView.ExerciseState,
    text: String
) -> some View {
    VStack(spacing: 4) {
        Text(
            exerciseState == .completed  ? "Great job!" :
            exerciseState == .paused     ? "Paused" :
            (exerciseState == .notStarted || exerciseState == .ready) ? "Ready when you are" : text
        )
        .font(.title3.weight(.semibold))
        .fontDesign(.rounded)
        .foregroundStyle(Color.motherTextHeading)
        .multilineTextAlignment(.center)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.spring(duration: 0.4), value: text)

        if exerciseState == .paused {
            Text("Tap Resume to continue")
                .font(.caption)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
        }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 4)
}


struct PelvicFloorSessionView: View {
    let exerciseState: ExerciseDetailView.ExerciseState
    let seconds: Int
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    @StateObject private var voiceManager = VoiceGuidanceManager()

    private var totalCycleTime: Int { PelvicFloorPhase.allCases.reduce(0) { $0 + $1.duration } }

    private var currentPhase: PelvicFloorPhase {
        guard exerciseState == .active || exerciseState == .paused else { return .lieDown }
        let cycleSeconds = seconds % totalCycleTime
        var accumulated = 0
        for phase in PelvicFloorPhase.allCases {
            accumulated += phase.duration
            if cycleSeconds < accumulated { return phase }
        }
        return .lieDown
    }

    private var isRunning: Bool { exerciseState == .active || exerciseState == .paused }

    var body: some View {
        VStack(spacing: 18) {
            imageCard
            if isRunning {
                phaseStrip(
                    phases: PelvicFloorPhase.allCases,
                    current: currentPhase,
                    completed: { phase in
                        guard let ci = PelvicFloorPhase.allCases.firstIndex(of: currentPhase),
                              let pi = PelvicFloorPhase.allCases.firstIndex(of: phase) else { return false }
                        return pi < ci
                    }
                )
            }
            timerBlock(seconds: seconds)
            instructionLabel(exerciseState: exerciseState, text: currentPhase.instruction)
            controlButtons(
                exerciseState: exerciseState,
                onStartEnd: { if isRunning { onEnd() } else { onStart() } },
                onPauseResume: {
                    if exerciseState == .active { onPause() }
                    else if exerciseState == .paused { onResume() }
                }
            )
        }
        .onChange(of: currentPhase) { _, newPhase in
            if exerciseState == .active { voiceManager.speak(newPhase.instruction) }
        }
        .onChange(of: exerciseState) { _, newState in
            switch newState {
            case .paused, .notStarted, .ready, .completed: voiceManager.stopSpeaking()
            case .active: voiceManager.speak(currentPhase.instruction)
            }
        }
        .onDisappear { voiceManager.stopSpeaking() }
    }

    private var imageCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.motherPrimary.opacity(0.10), radius: 16, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.motherPrimary.opacity(0.04), Color.clear],
                    startPoint: .top, endPoint: .center
                ))

            if exerciseState == .completed {
                completionView(subtitle: "Great job strengthening your core.")
            } else {
                Image(currentPhase.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .id(currentPhase.imageName)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97)),
                        removal: .opacity
                    ))
                    .animation(.easeInOut(duration: 0.4), value: currentPhase.imageName)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
}


struct BreathingSessionView: View {
    let exerciseState: ExerciseDetailView.ExerciseState
    let seconds: Int
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void

    @StateObject private var voiceManager = VoiceGuidanceManager()

    private var totalCycleTime: Int { BreathingPhase.allCases.reduce(0) { $0 + $1.duration } }

    private var currentPhase: BreathingPhase {
        guard exerciseState == .active || exerciseState == .paused else { return .inhale }
        let cycleSeconds = seconds % totalCycleTime
        var accumulated = 0
        for phase in BreathingPhase.allCases {
            accumulated += phase.duration
            if cycleSeconds < accumulated { return phase }
        }
        return .inhale
    }

    private var isRunning: Bool { exerciseState == .active || exerciseState == .paused }

    var body: some View {
        VStack(spacing: 18) {
            breathingCircleCard
            if isRunning {
                phaseStrip(
                    phases: BreathingPhase.allCases,
                    current: currentPhase,
                    completed: { phase in
                        guard let ci = BreathingPhase.allCases.firstIndex(of: currentPhase),
                              let pi = BreathingPhase.allCases.firstIndex(of: phase) else { return false }
                        return pi < ci
                    }
                )
            }
            timerBlock(seconds: seconds)
            instructionLabel(exerciseState: exerciseState, text: currentPhase.instruction)
            controlButtons(
                exerciseState: exerciseState,
                onStartEnd: { if isRunning { onEnd() } else { onStart() } },
                onPauseResume: {
                    if exerciseState == .active { onPause() }
                    else if exerciseState == .paused { onResume() }
                }
            )
        }
        .onChange(of: currentPhase) { _, newPhase in
            if exerciseState == .active { voiceManager.speak(newPhase.instruction) }
        }
        .onChange(of: exerciseState) { _, newState in
            switch newState {
            case .paused, .notStarted, .ready, .completed: voiceManager.stopSpeaking()
            case .active: voiceManager.speak(currentPhase.instruction)
            }
        }
        .onDisappear { voiceManager.stopSpeaking() }
    }

    private var breathingCircleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.motherPrimary.opacity(0.10), radius: 16, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.motherPrimary.opacity(0.04), Color.clear],
                    startPoint: .top, endPoint: .center
                ))

            if exerciseState == .completed {
                completionView(subtitle: "Great job. Take a moment to rest.")
            } else {
                breathingCircle
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    private var breathingCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.motherPrimary.opacity(0.06))
                .frame(width: 200, height: 200)
                .scaleEffect(currentPhase == .inhale || currentPhase == .hold ? 1.15 : 0.85)
                .animation(animationForPhase, value: currentPhase)

            // Mid ring
            Circle()
                .fill(Color.motherPrimary.opacity(0.12))
                .frame(width: 200, height: 200)
                .scaleEffect(currentPhase.circleScale)
                .animation(animationForPhase, value: currentPhase)

            // Core circle
            Circle()
                .fill(RadialGradient(
                    colors: [Color.motherPrimary.opacity(0.75), Color.motherSecondary.opacity(0.55)],
                    center: .center, startRadius: 0, endRadius: 90
                ))
                .frame(width: 160, height: 160)
                .scaleEffect(currentPhase.circleScale)
                .animation(animationForPhase, value: currentPhase)

            // Icon + label inside circle
            VStack(spacing: 4) {
                Image(systemName: phaseIcon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                Text(currentPhase.instruction)
                    .font(.caption.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
            }
        }
    }

    private var animationForPhase: Animation {
        switch currentPhase {
        case .inhale: return .easeInOut(duration: Double(BreathingPhase.inhale.duration))
        case .exhale: return .easeInOut(duration: Double(BreathingPhase.exhale.duration))
        case .hold, .relax: return .linear(duration: 0.1)
        }
    }

    private var phaseIcon: String {
        switch currentPhase {
        case .inhale: return "arrow.down.circle"
        case .hold:   return "pause.circle"
        case .exhale: return "arrow.up.circle"
        case .relax:  return "heart.circle"
        }
    }
}


private func completionView(subtitle: String) -> some View {
    VStack(spacing: 14) {
        Text("🌸").font(.system(size: 72))
        Text("Exercise Complete!")
            .font(.title2.weight(.bold))
            .fontDesign(.rounded)
            .foregroundStyle(Color.motherTextHeading)
        Text(subtitle)
            .font(.subheadline)
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding(32)
}
