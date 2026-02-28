import SwiftUI

struct CommandsView: View {
    @ObservedObject var viewModel: ConfigViewModel

    @State private var id: UUID? = nil
    @State private var name = ""
    @State private var action: PTZAction = .presetRecall
    @State private var presetNumber = "1"
    @State private var buttonText = "Add"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commands")
                .font(.title2)
                .bold()

            HStack {
                LabeledContent("Name") {
                    TextField("Name", text: $name).frame(width: 200)
                }
                Picker("Action", selection: $action) {
                    Text("Preset Recall").tag(PTZAction.presetRecall)
                }
                .frame(width: 160)
                LabeledContent("Preset #") {
                    TextField("Preset #", text: $presetNumber)
                        .frame(width: 90)
                        .multilineTextAlignment(.trailing)
                }
                Button(buttonText) {
                    if (id == nil) {
                        addCommand()
                    } else {
                        updateCommand()
                    }
                }
                .tint(.blue)
                .disabled(name.isEmpty || Int(presetNumber) == nil)
                Button("Reset") {
                    resetForm()
                }
                .tint(.red)
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
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeCommandTemplate(command.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { edit(command) } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
            }
        }
    }
    
    private func addCommand() {
        let number = Int(presetNumber) ?? 1
        viewModel.addCommandTemplate(name: name, action: action, params: .presetRecall(number: number))
        resetForm()
    }
    
    private func updateCommand() {
        let commandTemplate = CommandTemplate(
            id: id!,
            name: name,
            action: action,
            params: .presetRecall(number: Int(presetNumber) ?? 1)
        )
        
        viewModel.updateCommandTemplate(commandTemplate)
        resetForm()
    }
    
    private func edit(_ command: CommandTemplate) {
        id = command.id
        name = command.name
        action = command.action
        switch command.params {
        case .presetRecall(number: let number):
            presetNumber = "\(number)"
        }
        buttonText = "Save"
    }
    
    private func resetForm() {
        name = ""
        presetNumber = "1"
        action = .presetRecall
    }
}
