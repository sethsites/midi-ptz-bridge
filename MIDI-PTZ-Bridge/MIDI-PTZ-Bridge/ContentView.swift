import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ConfigViewModel()

    var body: some View {
        ConfigWindow(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
