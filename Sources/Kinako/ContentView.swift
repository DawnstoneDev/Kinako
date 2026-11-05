import SwiftUI

struct ContentView: View {
    @Bindable var project: Project
    @State private var showInspector = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SourcePane(project: project)
                    .frame(width: 340)
                Divider()
                LayoutPane(project: project)
                    .frame(maxWidth: .infinity)
            }
            Divider()
            BuildBar(project: project)
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(project: project)
                .inspectorColumnWidth(min: 290, ideal: 320, max: 420)
        }
        .toolbar {
            ToolbarItem {
                Button { showInspector.toggle() } label: {
                    Label("設定パネル", systemImage: "sidebar.right")
                }
            }
        }
        .navigationTitle("Kinako")
    }
}

// MARK: - 共通部品

struct PaneHeader<Trailing: View>: View {
    let step: Int
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            Text("\(step)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(.subheadline.weight(.semibold)) }
}

/// 行き先の候補（プリセット＋自作フォルダ）
struct DestinationMenuContent: View {
    let project: Project
    let id: UUID

    var body: some View {
        ForEach(project.allDestinations, id: \.self) { path in
            Button(path) { project.setDestination(path, for: id) }
        }
    }
}

/// 項目まわりの操作（右クリック・「…」メニュー共通）
struct ItemActions: View {
    let project: Project
    let item: PayloadItem

    var body: some View {
        Menu("行き先を変更") { DestinationMenuContent(project: project, id: item.id) }
        Button("Finderで表示") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
        Divider()
        Button("一覧から外す", role: .destructive) { project.remove(item.id) }
    }
}

// MARK: - ① ファイル

struct SourcePane: View {
    let project: Project
    @State private var targeted = false

    var body: some View {
        VStack(spacing: 0) {
            PaneHeader(step: 1, title: "入れるファイル", subtitle: "ドロップするだけで追加") {
                HStack(spacing: 6) {
                    if !project.items.isEmpty {
                        Text("\(project.items.count)件")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Menu {
                            Button("すべて外す", role: .destructive) { project.removeAll() }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.hidden)
                        .frame(width: 24)
                    }
                    Button { project.pickFiles() } label: { Image(systemName: "plus") }
                        .help("ファイルを追加")
                }
            }
            Divider()
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(project.items) { item in
                        SourceRow(project: project, item: item)
                    }
                    DropZone(compact: !project.items.isEmpty, targeted: targeted) { project.pickFiles() }
                        .padding(.top, project.items.isEmpty ? 0 : 6)
                }
                .padding(10)
            }
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.delete) {
            guard let id = project.selection else { return .ignored }
            project.remove(id)
            return .handled
        }
        .dropDestination(for: URL.self, action: { urls, _ in
            project.add(urls: urls)
            return true
        }, isTargeted: { targeted = $0 })
    }
}

struct DropZone: View {
    let compact: Bool
    let targeted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: compact ? 18 : 34))
                    .foregroundStyle(targeted ? Color.accentColor : Color.secondary)
                Text(compact ? "さらに追加" : "ここにファイルをドロップ")
                    .font(.callout.weight(.medium))
                if !compact {
                    Text("クリックして選ぶこともできます\n.app・フォルダ・実行ファイル")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 12 : 48)
            .background(targeted ? Color.accentColor.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(targeted ? Color.accentColor : Color.secondary.opacity(0.4),
                                  style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct SourceRow: View {
    let project: Project
    let item: PayloadItem
    @State private var hovering = false

    private var selected: Bool { project.selection == item.id }

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).lineLimit(1).truncationMode(.middle)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold))
                    Text(item.displayDestination)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.caption.monospaced())
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            Spacer(minLength: 0)
            if hovering || selected {
                Menu {
                    ItemActions(project: project, item: item)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 24)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            selected ? Color.accentColor.opacity(0.18) : (hovering ? Color.primary.opacity(0.06) : Color.clear),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(selected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { project.selection = item.id }
        .onHover { hovering = $0 }
        .contextMenu { ItemActions(project: project, item: item) }
        .draggable(item.id.uuidString) {
            Label(item.name, systemImage: "doc")
                .padding(8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - ② 配置図

struct LayoutPane: View {
    let project: Project

    var body: some View {
        VStack(spacing: 0) {
            PaneHeader(step: 2, title: "インストール後の配置", subtitle: "ドラッグ&ドロップか、メニューで場所を変更") {
                if !project.collapsed.isEmpty {
                    Button("すべて展開") { project.collapsed.removeAll() }
                        .controlSize(.small)
                }
            }
            Divider()
            SelectionBar(project: project)
            Divider()

            if project.items.isEmpty && project.extraFolders.isEmpty {
                ContentUnavailableView(
                    "配置図はここに出ます",
                    systemImage: "folder.badge.gearshape",
                    description: Text("左にファイルを追加すると、入る場所がフォルダ構造で見えます")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    TreeRowView(node: project.tree, depth: 0, project: project)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(nsColor: .controlBackgroundColor))
            }

            Divider()
            PalettePanel(project: project)
        }
    }
}

struct SelectionBar: View {
    let project: Project

    var body: some View {
        HStack(spacing: 10) {
            if let item = project.selectedItem {
                Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(item.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Text("行き先").font(.caption).foregroundStyle(.secondary)
                Menu {
                    DestinationMenuContent(project: project, id: item.id)
                } label: {
                    Label(item.displayDestination, systemImage: "folder")
                        .lineLimit(1)
                }
                .frame(maxWidth: 260)
                Button { project.remove(item.id) } label: { Image(systemName: "trash") }
                    .help("一覧から外す")
            } else {
                Image(systemName: "cursorarrow.click.2").foregroundStyle(.secondary)
                Text("項目を選ぶと、ここで行き先を変えられます")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(.bar)
    }
}

struct TreeRowView: View {
    let node: TreeNode
    let depth: Int
    let project: Project
    @State private var targeted = false
    @State private var hovering = false

    private var isItem: Bool { node.item != nil }
    private var isSelected: Bool { node.item != nil && node.item?.id == project.selection }
    private var canCollapse: Bool { !isItem && depth > 0 && !node.children.isEmpty }
    private var isCollapsed: Bool { canCollapse && project.collapsed.contains(node.path) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            rowWithDrop
            if !isCollapsed {
                ForEach(node.children) { child in
                    TreeRowView(node: child, depth: depth + 1, project: project)
                }
            }
        }
    }

    @ViewBuilder
    private var rowWithDrop: some View {
        if let item = node.item {
            row
                .contextMenu { ItemActions(project: project, item: item) }
                .draggable(item.id.uuidString) {
                    Label(item.name, systemImage: "doc")
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
        } else {
            row
                .dropDestination(for: URL.self, action: { urls, _ in
                    project.add(urls: urls, destination: node.path)
                    return true
                }, isTargeted: { targeted = $0 })
                .dropDestination(for: String.self, action: { strings, _ in
                    if let s = strings.first { project.move(idString: s, to: node.path) }
                    return true
                }, isTargeted: { targeted = $0 })
        }
    }

    private var row: some View {
        HStack(spacing: 0) {
            ForEach(0..<depth, id: \.self) { _ in
                Rectangle()
                    .fill(Color.primary.opacity(0.10))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .padding(.leading, 9)
                    .padding(.trailing, 10)
            }
            HStack(spacing: 8) {
                chevron
                icon
                Text(depth == 0 ? "Macのディスク ( / )" : node.name)
                    .fontWeight(isItem ? .semibold : .regular)
                    .foregroundStyle(isItem ? Color.primary : Color.secondary)
                    .lineLimit(1)
                if isItem {
                    Text("追加")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                if isCollapsed {
                    Text("\(node.itemCount)件")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }
                Spacer(minLength: 0)
                if let item = node.item, hovering || isSelected {
                    Menu {
                        ItemActions(project: project, item: item)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 24)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(targeted ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .padding(.vertical, 1)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture {
            if let item = node.item {
                project.selection = item.id
            } else if canCollapse {
                project.toggleCollapsed(node.path)
            }
        }
    }

    private var rowBackground: Color {
        if isSelected { return Color.accentColor.opacity(0.20) }
        if targeted { return Color.accentColor.opacity(0.12) }
        if hovering { return Color.primary.opacity(0.05) }
        if isItem { return Color.accentColor.opacity(0.06) }
        return .clear
    }

    @ViewBuilder
    private var chevron: some View {
        if canCollapse {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 12)
        } else {
            Color.clear.frame(width: 12, height: 1)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let item = node.item {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable()
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: depth == 0 ? "internaldrive.fill" : "folder.fill")
                .foregroundStyle(.secondary)
                .frame(width: 22)
        }
    }
}

// MARK: - 場所パレット

struct PalettePanel: View {
    let project: Project
    @State private var newPath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                SectionTitle("場所パレット")
                Text("クリックで移動 ／ ドロップで追加・移動")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                TextField("", text: $newPath, prompt: Text("/新しい/場所"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 170)
                    .onSubmit(addFolder)
                Button(action: addFolder) { Image(systemName: "plus") }
                    .help("場所を追加")
                    .disabled(newPath.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 6)], spacing: 6) {
                    ForEach(project.allDestinations, id: \.self) { path in
                        PresetChip(path: path, project: project)
                    }
                }
            }
            .frame(maxHeight: 104)
        }
        .padding(12)
        .background(.bar)
    }

    private func addFolder() {
        project.addFolder(newPath)
        newPath = ""
    }
}

struct PresetChip: View {
    let path: String
    let project: Project
    @State private var targeted = false

    private var isCurrent: Bool { project.selectedItem?.displayDestination == path }
    private var isCustom: Bool { project.extraFolders.contains(path) }

    var body: some View {
        Button {
            if let id = project.selection { project.setDestination(path, for: id) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isCurrent ? "checkmark.circle.fill" : (isCustom ? "folder.badge.plus" : "folder"))
                    .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                Text(path)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                targeted ? Color.accentColor.opacity(0.18) : (isCurrent ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.05)),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(targeted ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isCustom {
                Button("この場所を削除", role: .destructive) { project.removeFolder(path) }
            }
        }
        .dropDestination(for: URL.self, action: { urls, _ in
            project.add(urls: urls, destination: path)
            return true
        }, isTargeted: { targeted = $0 })
        .dropDestination(for: String.self, action: { strings, _ in
            if let s = strings.first { project.move(idString: s, to: path) }
            return true
        }, isTargeted: { targeted = $0 })
    }
}

// MARK: - ③ 設定（右の半透明パネル）

struct InspectorView: View {
    @Bindable var project: Project

    var body: some View {
        Form {
            Section("③ パッケージ情報") {
                TextField("名前", text: $project.name)
                TextField("識別子", text: $project.identifier, prompt: Text("com.example.myapp"))
                if project.identifier.contains(" ") {
                    Text("識別子に空白は使えません").font(.caption).foregroundStyle(.red)
                }
                TextField("バージョン", text: $project.version)
            }

            Section("選択中の項目") {
                if let item = project.selectedItem {
                    LabeledContent("項目") {
                        Text(item.name).lineLimit(1).truncationMode(.middle)
                    }
                    TextField(
                        "インストール先",
                        text: Binding(
                            get: { item.destination },
                            set: { project.setDestination($0, for: item.id) }
                        )
                    )
                    .font(.body.monospaced())
                    Menu("よく使う場所から選ぶ") {
                        DestinationMenuContent(project: project, id: item.id)
                    }
                    Button("一覧から外す", role: .destructive) { project.remove(item.id) }
                } else {
                    Text("左の一覧か配置図で項目を選ぶと、行き先を変えられます")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section("スクリプト（任意）") {
                ScriptRow(title: "インストール前", url: project.preinstall,
                          pick: { project.pickScript(isPre: true) },
                          clear: { project.preinstall = nil })
                ScriptRow(title: "インストール後", url: project.postinstall,
                          pick: { project.pickScript(isPre: false) },
                          clear: { project.postinstall = nil })
            }

            Section("署名（任意）") {
                TextField("署名ID", text: $project.signingIdentity,
                          prompt: Text("Developer ID Installer: 名前 (TEAMID)"))
            }
        }
        .formStyle(.grouped)
    }
}

struct ScriptRow: View {
    let title: String
    let url: URL?
    let pick: () -> Void
    let clear: () -> Void

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                Text(url?.lastPathComponent ?? "なし")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("選ぶ", action: pick)
                if url != nil {
                    Button(action: clear) { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.borderless)
                }
            }
        }
    }
}

// MARK: - 下部バー

struct BuildBar: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            status
            Spacer()
            Button {
                Task { await project.build() }
            } label: {
                Label("pkgを作成", systemImage: "shippingbox.fill")
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!project.canBuild)
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
    }

    @ViewBuilder
    private var status: some View {
        switch project.state {
        case .idle:
            Label(
                project.items.isEmpty ? "ファイルを追加してください" : "\(project.items.count)個の項目 → \(project.name)-\(project.version).pkg",
                systemImage: "info.circle"
            )
            .foregroundStyle(.secondary)
        case .building:
            ProgressView().controlSize(.small)
            Text("作成中…")
        case .success(let url):
            Label("作成しました：\(url.lastPathComponent)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Button("Finderで表示") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
        case .failure(let message):
            Label("失敗しました", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .lineLimit(2)
                .textSelection(.enabled)
                .foregroundStyle(.secondary)
        }
    }
}
