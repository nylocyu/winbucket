import SwiftUI

struct OnboardingView: View {
    static let hasSeenOnboardingKey = "hasSeenOnboarding"

    private struct Step {
        let icon: String
        let text: String
    }

    private static let steps: [Step] = [
        Step(icon: "arrow.down.square", text: "Ziehe Screenshots, Dateien oder Ordner auf das Menüleisten-Icon, um einen Win zu speichern."),
        Step(icon: "timer", text: "Halte eine Datei kurz über das Icon – der Bucket öffnet sich automatisch."),
        Step(icon: "note.text", text: "Schreib eine kurze Notiz dazu. Fertig für die nächste Gehaltsverhandlung.")
    ]

    let onFinish: () -> Void
    @State private var step = 0

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: Self.steps[step].icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text(Self.steps[step].text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button(step == Self.steps.count - 1 ? "Los geht's" : "Weiter") {
                if step == Self.steps.count - 1 {
                    onFinish()
                } else {
                    step += 1
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(width: 320, height: 460)
    }
}
