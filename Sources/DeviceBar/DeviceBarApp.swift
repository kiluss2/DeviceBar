import SwiftUI

@main
struct DeviceBarApp: App {
    @State private var store = DeviceStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store)
        } label: {
            Image(nsImage: store.busyAction == nil ? MenuBarIcon.idle : MenuBarIcon.busy)
                .task { await store.startAutoRefresh() }
        }
        .menuBarExtraStyle(.window)

        Window("DeviceBar", id: MainWindow.id) {
            MainWindow(store: store)
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentSize)
    }
}
