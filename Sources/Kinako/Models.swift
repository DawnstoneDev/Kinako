import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PayloadItem: Identifiable, Sendable {
    let id = UUID()
    let url: URL
    var destination: String

    var name: String { url.lastPathComponent }

    var destinationComponents: [String] {
        destination.split(separator: "/").map(String.init).filter { $0 != "." && $0 != ".." }
    }

    var displayDestination: String { "/" + destinationComponents.joined(separator: "/") }
}

final class TreeNode: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    var children: [TreeNode] = []
    var item: PayloadItem?

    init(name: String, path: String, item: PayloadItem? = nil) {
        self.name = name
        self.path = path
        self.item = item
    }

    var itemCount: Int {
        (item != nil ? 1 : 0) + children.reduce(0) { $0 + $1.itemCount }
    }

    func sortRecursively() {
        children.sort { a, b in
            let af = a.item == nil, bf = b.item == nil
            if af != bf { return af }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
        children.forEach { $0.sortRecursively() }
    }
}

enum BuildState {
    case idle, building, success(URL), failure(String)

    var isBuilding: Bool {
        if case .building = self { return true }
        return false
    }
}

enum Presets {
    static let destinations = [
        "/Applications",
        "/usr/local/bin",
        "/usr/local/lib",
        "/Library/Application Support",
        "/Library/LaunchDaemons",
        "/Library/LaunchAgents",
        "/Library/Fonts",
        "/Library/Frameworks",
    ]
}

@Observable
@MainActor
final class Project {
    var name = "MyApp"
    var identifier = "com.example.myapp"
    var version = "1.0.0"
    var items: [PayloadItem] = []
    var selection: UUID?
    var preinstall: URL?
    var postinstall: URL?
    var signingIdentity = ""
    var state: BuildState = .idle

    /// 自分で追加した行き先フォルダ
    var extraFolders: [String] = []
    /// 配置図で折りたたんでいるフォルダ
    var collapsed: Set<String> = []

    var selectedItem: PayloadItem? { items.first { $0.id == selection } }

    var allDestinations: [String] {
        var result = Presets.destinations
        for f in extraFolders where !result.contains(f) { result.append(f) }
        return result
    }

    var canBuild: Bool {
        !items.isEmpty
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !identifier.trimmingCharacters(in: .whitespaces).isEmpty
            && !version.trimmingCharacters(in: .whitespaces).isEmpty
            && !state.isBuilding
    }

    var tree: TreeNode {
        let root = TreeNode(name: "/", path: "/")

        func folder(_ comps: [String]) -> TreeNode {
            var current = root
            var path = ""
            for comp in comps {
                path += "/" + comp
                if let next = current.children.first(where: { $0.name == comp && $0.item == nil }) {
                    current = next
                } else {
                    let node = TreeNode(name: comp, path: path)
                    current.children.append(node)
                    current = node
                }
            }
            return current
        }

        for f in extraFolders {
            _ = folder(f.split(separator: "/").map(String.init))
        }
        for item in items {
            let dir = folder(item.destinationComponents)
            dir.children.append(TreeNode(name: item.name, path: dir.path, item: item))
        }
        root.sortRecursively()
        return root
    }

    // MARK: 編集

    func move(idString: String, to path: String) {
        guard let id = UUID(uuidString: idString), items.contains(where: { $0.id == id }) else { return }
        setDestination(path, for: id)
        selection = id
    }

    func add(urls: [URL], destination: String? = nil) {
        for url in urls where !items.contains(where: { $0.url == url }) {
            let item = PayloadItem(url: url, destination: destination ?? defaultDestination(for: url))
            items.append(item)
            selection = item.id
        }
        state = .idle
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        if selection == id { selection = nil }
        state = .idle
    }

    func removeAll() {
        items.removeAll()
        selection = nil
        state = .idle
    }

    func setDestination(_ destination: String, for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].destination = destination
        state = .idle
    }

    func addFolder(_ raw: String) {
        let comps = raw.split(separator: "/").map(String.init).filter { !$0.isEmpty && $0 != "." && $0 != ".." }
        guard !comps.isEmpty else { return }
        let path = "/" + comps.joined(separator: "/")
        if !allDestinations.contains(path) { extraFolders.append(path) }
    }

    func removeFolder(_ path: String) {
        extraFolders.removeAll { $0 == path }
    }

    func toggleCollapsed(_ path: String) {
        if collapsed.contains(path) { collapsed.remove(path) } else { collapsed.insert(path) }
    }

    private func defaultDestination(for url: URL) -> String {
        if url.pathExtension == "app" { return "/Applications" }
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        if !isDir && FileManager.default.isExecutableFile(atPath: url.path) { return "/usr/local/bin" }
        return "/Library/Application Support"
    }

    // MARK: パネル

    func pickFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "pkgに入れるファイルやフォルダを選んでください"
        if panel.runModal() == .OK { add(urls: panel.urls) }
    }

    func pickScript(isPre: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if isPre { preinstall = url } else { postinstall = url }
    }

    // MARK: ビルド

    func build() async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "pkg") ?? .data]
        panel.nameFieldStringValue = "\(name)-\(version).pkg"
        panel.message = "pkgの保存先を選んでください"
        guard panel.runModal() == .OK, let output = panel.url else { return }

        let spec = BuildSpec(
            identifier: identifier.trimmingCharacters(in: .whitespaces),
            version: version.trimmingCharacters(in: .whitespaces),
            items: items,
            preinstall: preinstall,
            postinstall: postinstall,
            signing: signingIdentity.trimmingCharacters(in: .whitespaces),
            output: output
        )
        state = .building
        do {
            try await Task.detached { try Builder.build(spec) }.value
            state = .success(output)
        } catch {
            state = .failure(error.localizedDescription)
        }
    }
}
