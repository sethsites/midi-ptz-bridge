import SwiftUI

struct ConfigWindow: View {
    @ObservedObject var viewModel: ConfigViewModel

    var body: some View {
        TabView {
            MidiSourcesView(viewModel: viewModel)
                .tabItem { Text("MIDI") }
            CamerasView(viewModel: viewModel)
                .tabItem { Text("Cameras") }
            CommandsView(viewModel: viewModel)
                .tabItem { Text("Commands") }
            RulesView(viewModel: viewModel)
                .tabItem { Text("Rules") }
        }
        .padding(16)
        .frame(minWidth: 720, minHeight: 520)
    }
}
