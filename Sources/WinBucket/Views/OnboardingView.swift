import SwiftUI
import AppKit

struct OnboardingView: View {
    static let hasSeenOnboardingKey = "hasSeenOnboarding"

    private enum StepIcon {
        case system(String)
        case bucket
    }

    private struct Step {
        let icon: StepIcon
        let text: String
    }

    private static let steps: [Step] = [
        Step(icon: .system("arrow.down.square"), text: "Drag screenshots, files or folders onto the menu bar icon to save a win."),
        Step(icon: .bucket, text: "Hold a file over the icon briefly – the bucket opens automatically."),
        Step(icon: .system("note.text"), text: "Write a short note about it. Ready for your next salary negotiation.")
    ]

    let onFinish: () -> Void
    @State private var step = 0

    @ViewBuilder
    private var stepIcon: some View {
        switch Self.steps[step].icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 48))
        case .bucket:
            Image(nsImage: BucketIcon.image(pointSize: 96))
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            stepIcon
                .foregroundStyle(Color.accentColor)
            Text(Self.steps[step].text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button(step == Self.steps.count - 1 ? "Get Started" : "Next") {
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
