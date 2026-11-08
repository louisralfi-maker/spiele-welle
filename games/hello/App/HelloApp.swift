import SwiftUI

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup {
            HelloView()
        }
    }
}

struct HelloView: View {
    @State private var counter = Counter()

    var body: some View {
        VStack(spacing: 24) {
            Text("Hello, wave!")
                .font(.largeTitle.bold())
            Text("Taps: \(counter.value)")
                .font(.title2)
                .monospacedDigit()
                .accessibilityIdentifier("hello-count")
            Button("Tap me") {
                counter.tap()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("hello-tap")
        }
        .padding()
    }
}
