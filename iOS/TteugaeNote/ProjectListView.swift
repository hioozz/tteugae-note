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
            list
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("뜨개노트")
            .toolbar(.hidden, for: .navigationBar)   // 웹처럼 화면 안에 머리말을 그려요
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
                header
                HStack(spacing: 8) {
                    Button { showLibrary = true } label: { Label("도안함", lucide: "book") }
                    Button { showStash = true } label: { Label("보관함", lucide: "shippingbox") }
                    Button { showDone = true } label: { Label("완성작 \(done.count)", lucide: "checkmark.seal") }
                }
                .buttonStyle(ChipStyle())

                if store.projects.isEmpty {
                    EmptyStateView(title: "첫 작품을 시작해 보세요",
                                   message: "단수를 세고, 반복 작업을 알려주고,\n실과 바늘 정보도 함께 기억해 둘게요.",
                                   buttonTitle: "새 작품 만들기",
                                   action: { showNew = true })
                        .padding(.top, 40)
                } else if knitting.isEmpty {
                    EmptyStateView(title: "지금 뜨는 작품이 없어요",
                                   message: "새 작품을 시작하거나\n도안함에 저장해 둔 도안으로 바로 시작해 보세요.",
                                   buttonTitle: "새 작품 만들기",
                                   action: { showNew = true })
                        .padding(.top, 40)
                } else {
                    ForEach(knitting) { p in
                        NavigationLink(value: p.id) { ProjectCard(project: p) }
                            .buttonStyle(.plain)
                    }
                }

                footer.padding(.top, 24)
            }
            .padding(16)
        }
    }

    /// 로고 + 제목 + 오늘 뜬 단 + 새 작품 버튼 (웹과 같은 모양)
    private var header: some View {
        HStack(spacing: 12) {
            Image("YarnLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("뜨개노트").appFont(size: 26, relativeTo: .title)
                let today = store.rowsToday()
                Text(today > 0 ? "오늘 \(today)단 떴어요" : "오늘도 한 단씩")
                    .appFont(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            if !store.projects.isEmpty {
                Button { showNew = true } label: {
                    Label("새 작품", lucide: "plus")
                        .appFont(.subheadline)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                }
                .buttonStyle(PressStyle(bg: Theme.accent, fg: Theme.accentInk, radius: 20))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    /// 화면 맨 아래 글자 링크: 백업·설정
    private var footer: some View {
        HStack(spacing: 10) {
            Button {
                exportDoc = BackupDocument(data: store.exportData())
                showExporter = true
            } label: { Text("백업 내보내기").underline() }
            Text("·").accessibilityHidden(true)
            Button { showImporter = true } label: { Text("백업 가져오기").underline() }
            Text("·").accessibilityHidden(true)
            Button { showSettings = true } label: { Text("설정").underline() }
        }
        .buttonStyle(.plain)
        .appFont(.footnote)
        .foregroundStyle(Theme.muted)
        .frame(maxWidth: .infinity)
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
                    .appFont(.headline)
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
                Text(project.meta).appFont(.subheadline).foregroundStyle(Theme.muted)
            }
            if project.isPaused && !project.resumeNote.isEmpty {
                Text("“\(project.resumeNote)”").appFont(.subheadline).foregroundStyle(Theme.warnInk).lineLimit(2)
            }
            if let pr = project.progress {
                ProgressBar(value: pr).padding(.top, 8)
                Text("\(project.row) / \(project.targetRows)단 · \(Int((pr * 100).rounded()))%")
                    .appFont(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            Text("\(project.updatedDate, format: .relative(presentation: .named)) 수정")
                .appFont(.caption)
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
