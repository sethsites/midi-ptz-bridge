import SwiftUI

struct RulesView: View {
    @ObservedObject var viewModel: ConfigViewModel

    @State private var note = "60"
    @State private var onOff: MidiOnOff = .on
    @State private var velocityType: VelocityType = .exact
    @State private var velocityValue = "100"
    @State private var velocityMin = "0"
    @State private var velocityMax = "127"
    @State private var selectedCamera: UUID?
    @State private var selectedCommand: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rules")
                .font(.title2)
                .bold()

            HStack {
                TextField("Note", text: $note)
                    .frame(width: 60)
                Picker("On/Off", selection: $onOff) {
                    Text("On").tag(MidiOnOff.on)
                    Text("Off").tag(MidiOnOff.off)
                }
                .frame(width: 90)

                Picker("Velocity", selection: $velocityType) {
                    Text("Exact").tag(VelocityType.exact)
                    Text("Min").tag(VelocityType.min)
                    Text("Max").tag(VelocityType.max)
                    Text("Range").tag(VelocityType.range)
                }
                .frame(width: 110)

                velocityInputs

                Picker("Camera", selection: $selectedCamera) {
                    Text("None").tag(UUID?.none)
                    ForEach(viewModel.config.cameras) { camera in
                        Text(camera.name).tag(Optional(camera.id))
                    }
                }
                .frame(width: 160)

                Picker("Command", selection: $selectedCommand) {
                    Text("None").tag(UUID?.none)
                    ForEach(viewModel.config.commandTemplates) { command in
                        Text(command.name).tag(Optional(command.id))
                    }
                }
                .frame(width: 160)

                Button("Add") {
                    addRule()
                }
                .disabled(Int(note) == nil)
            }

            List {
                ForEach(viewModel.config.rules) { rule in
                    VStack(alignment: .leading) {
                        Text("Note \(rule.note) \(rule.onOff == .on ? "On" : "Off")")
                            .bold()
                        Text(velocityDescription(rule.velocity))
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: viewModel.removeRules)
            }
        }
    }

    private var velocityInputs: some View {
        HStack {
            switch velocityType {
            case .exact, .min, .max:
                TextField("Value", text: $velocityValue)
                    .frame(width: 60)
            case .range:
                TextField("Min", text: $velocityMin)
                    .frame(width: 60)
                TextField("Max", text: $velocityMax)
                    .frame(width: 60)
            }
        }
    }

    private func addRule() {
        let noteValue = Int(note) ?? 0
        let velocity: VelocityCondition
        switch velocityType {
        case .exact:
            velocity = .exact(Int(velocityValue) ?? 0)
        case .min:
            velocity = .min(Int(velocityValue) ?? 0)
        case .max:
            velocity = .max(Int(velocityValue) ?? 0)
        case .range:
            velocity = .range(Int(velocityMin) ?? 0, Int(velocityMax) ?? 127)
        }

        viewModel.addRule(note: noteValue, onOff: onOff, velocity: velocity, cameraId: selectedCamera, commandTemplateId: selectedCommand)
    }

    private func velocityDescription(_ velocity: VelocityCondition) -> String {
        switch velocity {
        case .exact(let value):
            return "Velocity = \(value)"
        case .min(let value):
            return "Velocity >= \(value)"
        case .max(let value):
            return "Velocity <= \(value)"
        case .range(let minValue, let maxValue):
            return "Velocity \(minValue)-\(maxValue)"
        }
    }

    private enum VelocityType {
        case exact
        case min
        case max
        case range
    }
}
