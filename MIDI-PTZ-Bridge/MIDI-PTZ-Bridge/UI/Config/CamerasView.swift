import SwiftUI

struct CamerasView: View {
    @ObservedObject var viewModel: ConfigViewModel

    @State private var id: UUID? = nil
    @State private var name = ""
    @State private var scheme: CameraScheme = .http
    @State private var host = ""
    @State private var port = "80"
    @State private var username = ""
    @State private var password = ""
    @State private var buttonText = "Add"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cameras")
                .font(.title2)
                .bold()

            
            HStack {
                LabeledContent("Name") {
                    TextField("Name", text: $name).frame(width: 100)
                }
                Spacer()
                Picker("Scheme", selection: $scheme) {
                    Text("http").tag(CameraScheme.http)
                    Text("https").tag(CameraScheme.https)
                }
                .frame(width: 150)
                Spacer()
                LabeledContent("Host") {
                    TextField("Host", text: $host).frame(width: 150)
                }
                Spacer()
                LabeledContent("Port") {
                    TextField("Port", text: $port)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                }
            }
            HStack {
                LabeledContent("Username") {
                    TextField("Username", text: $username).frame(width: 150)
                }
                Spacer()
                LabeledContent("Password") {
                    SecureField("Password", text: $password).frame(width: 150)
                }
                Spacer()
                Button(buttonText) {
                    if (id == nil) {
                        addCamera()
                    } else {
                        updateCamera()
                    }
                }
                .tint(.blue)
                .disabled(name.isEmpty || host.isEmpty || Int(port) == nil)
                Button("Reset") {
                    resetForm()
                }
                .tint(.red)
                .disabled(name.isEmpty || host.isEmpty || Int(port) == nil)
            }

            List {
                ForEach(viewModel.config.cameras) { camera in
                    VStack(alignment: .leading) {
                        Text(camera.name)
                            .bold()
                        Text("\(camera.scheme.rawValue)://\(camera.host):\(camera.port)")
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeCamera(camera.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { edit(camera) } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
            }
        }
    }
    
    private func addCamera() {
        let portValue = Int(port) ?? 0
        viewModel.addCamera(
            name: name,
            scheme: scheme,
            host: host,
            port: portValue,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password
        )
        resetForm()
    }
    
    private func updateCamera() {
        let portValue = Int(port) ?? 0
        let tempCamera = Camera(
            id: id!,
            name: name,
            scheme: scheme,
            host: host,
            port: portValue,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password
        )
        
        viewModel.updateCamera(tempCamera)
        resetForm()
    }
    
    private func edit(_ camera: Camera) {
        id = camera.id
        name = camera.name
        host = camera.host
        port = "\(camera.port)"
        username = camera.username ?? ""
        password = camera.password ?? ""
        buttonText = "Save"
    }
    
    private func resetForm() {
        id = nil
        name = ""
        host = ""
        port = "80"
        username = ""
        password = ""
        buttonText = "Add"
    }
}
