import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast

    @State private var path: [String] = []
    @State private var showNew = false
    @State private var newProjectID: String?
    @State private var showSettings = false
    @State private var showDone = false
    @State private var showStash = false
    @State private var showLibrary = false
    @State private var showImporter = false
    @State private var showExporter = false
    @State private var exportDoc: BackupDocument?
    @State private var pendingImport: [Project]?
    @State private var pendingStash: Stash?

    /// 뜨는 중인 작품 (잠시 멈춘 작품은 아래쪽에)
    private var knitting: [Project] {
        store.projects.filter { !$0.isDone }.sorted {
            $0.isPaused != $1.isPaused ? !$0.isPaused : $0.updatedAt > $1.updatedAt
        }
    }
    private var done: [Project] { store.projects.filter(\.isDone) }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.projects.isEmpty { emptyState } else { list }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("뜨개노트")
            .toolbar { toolbarContent }
            .navigationDestination(for: String.self) { CounterView(projectID: $0) }
            .fileExporter(isPresented: $showExporter,
                          document: exportDoc,
                          contentType: .json,
                          defaultFilename: "뜨개노트-백업-\(Store.todayKey())") { result in
                if case .success = result { toast.show("백업 파일을 저장했어요") }
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { handleImport($0) }
        .sheet(isPresented: $showNew, onDismiss: openNewProject) {
            ProjectFormView(project: nil) { newProjectID = $0 }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showDone, onDismiss: openNewProject) { DoneProjectsView { newProjectID = $0 } }
        .sheet(isPresented: $showStash) { StashView() }
        .sheet(isPresented: $showLibrary, onDismiss: openNewProject) {
            PatternLibraryView { newProjectID = $0 }
        }
        .alert("작품 \(pendingImport?.count ?? 0)개를 가져올까요?", isPresented: importAlertShown) {
            Button("취소", role: .cancel) {}
            Button("가져오기") {
                if let list = pendingImport {
                    store.merge(list, stash: pendingStash)
                    toast.show("\(list.count)개 작품을 가져왔어요")
                }
            }
        } message: {
            Text("이미 있는 같은 작품은 백업 내용으로 바뀌어요.")
        }
    }

    // MARK: 화면 조각

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let today = store.rowsToday()
                Text(today > 0 ? "오늘 \(today)단 떴어요" : "오늘도 한 단씩")
                    .font(.app(.subheadline))
                    .foregroundStyle(Theme.muted)
                HStack(spacing: 8) {
                    Button { showLibrary = true } label: { Label("도안함", systemImage: "book") }
                    Button { showStash = true } label: { Label("보관함", systemImage: "shippingbox") }
                    Button { showDone = true } label: { Label("완성작 \(done.count)", systemImage: "checkmark.seal") }
                }
                .buttonStyle(ChipStyle())

                if knitting.isEmpty {
                    EmptyStateView(title: "지금 뜨는 작품이 없어요",
                                   message: "새 작품을 시작하거나\n도안함에 저장해 둔 도안으로 바로 시작해 보세요.",
                                   buttonTitle: "새 작품 만들기",
                                   action: { showNew = true },
                                   secondary: done.isEmpty ? nil : AnyView(
                                    Button { showDone = true } label: { Label("완성한 작품 보기", systemImage: "checkmark.seal") }
                                        .buttonStyle(ChipStyle())
                                   ))
                        .padding(.top, 50)
                } else {
                    ForEach(knitting) { p in
                        NavigationLink(value: p.id) { ProjectCard(project: p) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        EmptyStateView(title: "첫 작품을 시작해 보세요",
                       message: "단수를 세고, 반복 작업을 알려주고,\n실과 바늘 정보도 함께 기억해 둘게요.",
                       buttonTitle: "새 작품 만들기",
                       action: { showNew = true },
                       secondary: AnyView(
                        Button { showLibrary = true } label: { Label(store.patterns.isEmpty ? "도안함" : "도안함에서 시작", systemImage: "book") }
                            .buttonStyle(ChipStyle())
                       ))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    exportDoc = BackupDocument(data: store.exportData())
                    showExporter = true
                } label: { Label("백업 내보내기", systemImage: "square.and.arrow.up") }
                Button { showImporter = true } label: {
                    Label("백업 가져오기", systemImage: "square.and.arrow.down")
                }
                Divider()
                Button { showStash = true } label: { Label("실·바늘 보관함", systemImage: "shippingbox") }
                Button { showLibrary = true } label: { Label("도안함", systemImage: "book") }
                Button { showDone = true } label: { Label("완성한 작품", systemImage: "checkmark.seal") }
                Button { showSettings = true } label: { Label("설정", systemImage: "gearshape") }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("더보기")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showNew = true } label: { Label("새 작품", systemImage: "plus") }
        }
    }

    // MARK: 동작

    private func openNewProject() {
        if let id = newProjectID {
            path.append(id)
            newProjectID = nil
        }
    }

    private var importAlertShown: Binding<Bool> {
        Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } })
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            pendingImport = try Store.decodeBackup(data)
            pendingStash = Store.decodeStash(data)
        } catch {
            toast.show("백업 파일을 읽을 수 없어요")
        }
    }
}

struct ProjectCard: View {
    let project: Project

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let ph = project.photos.last {
                PhotoThumb(fileName: ph.fileName, size: 64)
            }
            info
        }
        .card(stroke: .clear)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        .contentShape(Rectangle())
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(project.name)
                    .font(.app(.headline))
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                if project.isDone {
                    Pill(text: "완성", fg: Theme.sage, bg: Theme.sageSoft)
                } else if project.isPaused {
                    Pill(text: "\(project.row)단에서 멈춤", fg: Theme.warnInk, bg: Theme.warnBg)
                } else {
                    Pill(text: "\(project.row)단")
                }
            }
            if !project.meta.isEmpty {
                Text(project.meta).font(.app(.subheadline)).foregroundStyle(Theme.muted)
            }
            if project.isPaused && !project.resumeNote.isEmpty {
                Text("“\(project.resumeNote)”").font(.app(.subheadline)).foregroundStyle(Theme.warnInk).lineLimit(2)
            }
            if let pr = project.progress {
                ProgressBar(value: pr).padding(.top, 8)
                Text("\(project.row) / \(project.targetRows)단 · \(Int((pr * 100).rounded()))%")
                    .font(.app(.subheadline))
                    .foregroundStyle(Theme.muted)
            }
            Text("\(project.updatedDate, format: .relative(presentation: .named)) 수정")
                .font(.app(.caption))
                .foregroundStyle(Theme.muted)
                .padding(.top, 2)
        }
    }
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
