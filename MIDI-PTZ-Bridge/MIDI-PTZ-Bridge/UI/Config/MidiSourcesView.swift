import SwiftUI

struct MidiSourcesView: View {
    @ObservedObject var viewModel: ConfigViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MIDI Sources")
                .font(.title2)
                .bold()

            HStack {
                Button("Refresh") {
                    viewModel.refreshMidiSources()
                }
            }

            List {
                if viewModel.availableMidiSources.isEmpty {
                    Text("No MIDI sources detected.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.availableMidiSources, id: \.self) { name in
                        Toggle(name, isOn: Binding(
                            get: { viewModel.config.midiSources.contains(name) },
                            set: { isSelected in
                                viewModel.setMidiSource(name, selected: isSelected)
                            }
                        ))
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshMidiSources()
        }
    }
}
