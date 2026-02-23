import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MIDI PTZ Bridge")
                .font(.title)
                .bold()

            Text("Configuration UI will live here.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 480)
    }
}

#Preview {
    ContentView()
}
