import SwiftUI

struct CamerasView: View {
    @ObservedObject var viewModel: ConfigViewModel

    @State private var name = ""
    @State private var scheme: CameraScheme = .http
    @State private var host = ""
    @State private var port = "80"
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cameras")
                .font(.title2)
                .bold()

            HStack {
                TextField("Name", text: $name)
                Picker("Scheme", selection: $scheme) {
                    Text("http").tag(CameraScheme.http)
                    Text("https").tag(CameraScheme.https)
                }
                .frame(width: 90)
                TextField("Host", text: $host)
                TextField("Port", text: $port)
                    .frame(width: 70)
                    .multilineTextAlignment(.trailing)
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
                Button("Add") {
                    let portValue = Int(port) ?? 0
                    viewModel.addCamera(
                        name: name,
                        scheme: scheme,
                        host: host,
                        port: portValue,
                        username: username.isEmpty ? nil : username,
                        password: password.isEmpty ? nil : password
                    )
                    name = ""
                    host = ""
                    port = "80"
                    username = ""
                    password = ""
                }
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
                }
                .onDelete(perform: viewModel.removeCameras)
            }
        }
    }
}
