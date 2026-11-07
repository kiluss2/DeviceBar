import SwiftUI

@main
struct DeviceBarApp: App {
    @State private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store)
        } label: {
            Image(systemName: store.busyAction == nil ? "iphone" : "iphone.badge.play")
                .task { await store.startAutoRefresh() }
        }
        .menuBarExtraStyle(.menu)

        Window("DeviceBar", id: MainWindow.id) {
            MainWindow(store: store)
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentSize)
    }
}
