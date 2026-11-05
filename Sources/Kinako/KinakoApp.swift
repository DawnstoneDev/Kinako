import SwiftUI

@main
struct KinakoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var project = Project()

    var body: some Scene {
        WindowGroup("Kinako") {
            ContentView(project: project)
                .frame(minWidth: 1100, minHeight: 640)
        }
        .defaultSize(width: 1240, height: 760)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
