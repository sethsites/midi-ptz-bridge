import SwiftUI

struct CommandsView: View {
    @ObservedObject var viewModel: ConfigViewModel

    @State private var name = ""
    @State private var action: PTZAction = .presetRecall
    @State private var presetNumber = "1"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commands")
                .font(.title2)
                .bold()

            HStack {
                TextField("Name", text: $name)
                Picker("Action", selection: $action) {
                    Text("Preset Recall").tag(PTZAction.presetRecall)
                }
                .frame(width: 160)
                TextField("Preset #", text: $presetNumber)
                    .frame(width: 90)
                    .multilineTextAlignment(.trailing)
                Button("Add") {
                    let number = Int(presetNumber) ?? 1
                    viewModel.addCommandTemplate(name: name, action: action, params: .presetRecall(number: number))
                    name = ""
                    presetNumber = "1"
                    action = .presetRecall
                }
                .disabled(name.isEmpty || Int(presetNumber) == nil)
            }

            List {
                ForEach(viewModel.config.commandTemplates) { command in
                    VStack(alignment: .leading) {
                        Text(command.name)
                            .bold()
                        switch command.params {
                        case .presetRecall(let number):
                            Text("preset_recall #\(number)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: viewModel.removeCommandTemplates)
            }
        }
    }
}
