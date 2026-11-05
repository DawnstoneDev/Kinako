import Foundation

struct BuildSpec: Sendable {
    let identifier: String
    let version: String
    let items: [PayloadItem]
    let preinstall: URL?
    let postinstall: URL?
    let signing: String
    let output: URL
}

struct KinakoError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum Builder {
    static func build(_ spec: BuildSpec) throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("Kinako-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: tmp) }

        let root = tmp.appendingPathComponent("root")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        // 1. 配置どおりにステージング
        for item in spec.items {
            var dir = root
            for comp in item.destinationComponents { dir.appendPathComponent(comp) }
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            let target = dir.appendingPathComponent(item.name)
            if fm.fileExists(atPath: target.path) {
                throw KinakoError(message: "同じ場所に同名の項目があります: \(item.displayDestination)/\(item.name)")
            }
            try fm.copyItem(at: item.url, to: target)
        }

        var args = [
            "--root", root.path,
            "--identifier", spec.identifier,
            "--version", spec.version,
            "--install-location", "/",
        ]

        // 2. スクリプト
        if spec.preinstall != nil || spec.postinstall != nil {
            let scripts = tmp.appendingPathComponent("scripts")
            try fm.createDirectory(at: scripts, withIntermediateDirectories: true)
            for (url, name) in [(spec.preinstall, "preinstall"), (spec.postinstall, "postinstall")] {
                guard let url else { continue }
                let dest = scripts.appendingPathComponent(name)
                try fm.copyItem(at: url, to: dest)
                try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
            }
            args += ["--scripts", scripts.path]
        }

        // 3. .app が勝手に別の場所へ「移動」されないよう、再配置を無効化
        let plistURL = tmp.appendingPathComponent("components.plist")
        if (try? run("/usr/bin/pkgbuild", ["--analyze", "--root", root.path, plistURL.path])) != nil,
           let data = try? Data(contentsOf: plistURL),
           let list = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [[String: Any]],
           !list.isEmpty {
            let fixed = list.map { entry -> [String: Any] in
                var e = entry
                e["BundleIsRelocatable"] = false
                return e
            }
            let out = try PropertyListSerialization.data(fromPropertyList: fixed, format: .xml, options: 0)
            try out.write(to: plistURL)
            args += ["--component-plist", plistURL.path]
        }

        // 4. 署名（任意）
        if !spec.signing.isEmpty { args += ["--sign", spec.signing] }

        args.append(spec.output.path)
        try run("/usr/bin/pkgbuild", args)
    }

    @discardableResult
    private static func run(_ executable: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self)
        guard process.terminationStatus == 0 else {
            throw KinakoError(message: text.isEmpty ? "pkgbuild が失敗しました" : text)
        }
        return text
    }
}
