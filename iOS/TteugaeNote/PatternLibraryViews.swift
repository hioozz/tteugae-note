import SwiftUI
import PhotosUI

// MARK: - 도안함: 저장해 둔 도안 목록

struct PatternLibraryView: View {
    /// 도안으로 작품을 시작하면 새 작품 id를 알려 줘요 (목록 화면이 그 작품을 열어요)
    var onStart: (String) -> Void

    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss
    @State private var editing: SavedPattern?

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.patterns.isEmpty {
                    emptyState
                        .containerRelativeFrame(.vertical) { h, _ in h * 0.9 }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(store.patterns) { sp in
                            SavedPatternCard(pattern: sp,
                                             onOpen: { editing = sp },
                                             onStart: { start(sp) })
                        }
                    }
                    .padding(16)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("도안함")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button { editing = SavedPattern() } label: { Label("도안 추가", systemImage: "plus") }
                }
            }
            .sheet(item: $editing) { SavedPatternSheet(pattern: $0, onStart: { start($0) }) }
        }
    }

    /// 처음 들어왔을 때: 화면 가운데에 그림과 설명
    private var emptyState: some View {
        EmptyStateView(title: "아직 저장한 도안이 없어요",
                       message: "자주 뜨는 도안을 넣어 두면\n도안 파일, 단별 안내, 실·바늘까지 담긴 채로\n바로 작품을 시작할 수 있어요.",
                       note: "뜨던 작품의 도안 메뉴에서 ‘도안함에 저장’으로도 넣을 수 있어요.",
                       buttonTitle: "도안 추가") { editing = SavedPattern() }
    }

    private func start(_ sp: SavedPattern) {
        guard let id = store.startProject(from: sp.id) else { return }
        Haptics.success()
        toast.show("‘\(sp.name)’ 작품을 시작했어요")
        onStart(id)
        dismiss()
    }
}

struct SavedPatternCard: View {
    let pattern: SavedPattern
    var onOpen: () -> Void
    var onStart: () -> Void

    private var meta: String {
        var parts: [String] = []
        if let f = pattern.file { parts.append(f.kind == .pdf ? "PDF" : "웹 링크") }
        if !pattern.guide.isEmpty { parts.append("\(pattern.guideMaxRow)단 안내") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: pattern.file?.kind == .web ? "globe" : "doc.richtext")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accentText)
                        .frame(width: 44, height: 44)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pattern.name.isEmpty ? "도안" : pattern.name).font(.app(.headline))
                        if !meta.isEmpty {
                            Text(meta).font(.app(.subheadline)).foregroundStyle(Theme.muted)
                        }
                        let mat = [pattern.yarn, pattern.needle].filter { !$0.isEmpty }.joined(separator: " · ")
                        if !mat.isEmpty {
                            Text(mat).font(.app(.subheadline)).foregroundStyle(Theme.muted).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onStart) {
                Label("이 도안으로 작품 시작", systemImage: "play.fill")
                    .labelStyle(TrailingIconLabelStyle())
                    .font(.app(.headline))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(PressStyle(bg: Theme.accent, fg: Theme.accentInk, radius: 16))
        }
        .foregroundStyle(Theme.text)
        .card()
    }
}

// MARK: - 도안 추가·편집

struct SavedPatternSheet: View {
    var onStart: ((SavedPattern) -> Void)?

    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss

    @State private var draft: SavedPattern
    @State private var guideText: String
    @State private var isNew: Bool
    @State private var newFiles: [String] = []
    @State private var showImporter = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showWeb = false
    @State private var webInput = ""
    @State private var reading = false
    @State private var readMessage: String?
    @State private var confirmDelete = false

    init(pattern: SavedPattern, onStart: ((SavedPattern) -> Void)? = nil) {
        self.onStart = onStart
        _draft = State(initialValue: pattern)
        _guideText = State(initialValue: SavedPatternSheet.text(of: pattern.guide))
        _isNew = State(initialValue: pattern.name.isEmpty && pattern.file == nil && pattern.guide.isEmpty)
    }

    static func text(of rows: [GuideRow]) -> String {
        rows.map { "\($0.label): \($0.text)" + ($0.total > 0 ? " (총\($0.total)코)" : "") }.joined(separator: "\n")
    }

    private var parsed: GuideParser.Result {
        GuideParser.parse(guideText.components(separatedBy: .newlines).enumerated().map { GuideParser.Line(text: $1, y: Double($0)) })
    }

    var body: some View {
        NavigationStack {
            Form {
                fileSection
                Section("도안") {
                    TextField("도안 이름 (예: 푸딩 줄 감개)", text: $draft.name)
                    TextField("실 (선택)", text: $draft.yarn)
                    TextField("바늘 (선택, 예: 6호)", text: $draft.needle)
                }
                guideSection
                Section("메모") {
                    TextField("작품을 시작할 때 메모로 들어가요", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...6)
                }
                if !isNew {
                    Section { Button("도안함에서 삭제", role: .destructive) { confirmDelete = true } }
                }
            }
            .navigationTitle(isNew ? "도안 추가" : "도안")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { newFiles.forEach(remove); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { if commit() { toast.show("도안함에 저장했어요"); dismiss() } }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if onStart != nil && !isNew {
                    Button {
                        if commit(), let saved = store.patterns.first(where: { $0.id == draft.id }) {
                            dismiss()
                            onStart?(saved)
                        }
                    } label: {
                        Label("이 도안으로 작품 시작", systemImage: "play.fill")
                            .labelStyle(TrailingIconLabelStyle())
                            .font(.app(.headline))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(PressStyle(bg: Theme.accent, fg: Theme.accentInk, radius: 18))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .background(Color(UIColor.systemGroupedBackground))
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf, .image]) { result in
                guard case .success(let url) = result else { return }
                do { setFile(try Store.storePatternFile(from: url)) } catch { toast.show("도안을 불러오지 못했어요") }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    defer { photoItem = nil }
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let pdf = PatternImport.pdfData(fromImage: image),
                          let ref = try? Store.storePatternData(pdf, title: "사진 도안") else {
                        toast.show("사진을 불러오지 못했어요")
                        return
                    }
                    setFile(ref)
                }
            }
            .alert("웹 도안 링크", isPresented: $showWeb) {
                TextField("https://", text: $webInput)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("취소", role: .cancel) {}
                Button("추가") {
                    if let url = Store.normalizedWebURL(webInput) {
                        setFile(PatternRef(kind: .web, title: url.host?.replacingOccurrences(of: "www.", with: "") ?? "웹 도안", fileName: nil, url: url.absoluteString))
                    } else {
                        toast.show("링크 주소를 확인해 주세요")
                    }
                }
            }
            .confirmationDialog("이 도안을 도안함에서 지울까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    newFiles.forEach(remove)
                    store.deletePattern(draft.id)
                    dismiss()
                }
            } message: { Text("이 도안으로 시작한 작품은 그대로 남아요.") }
        }
        .interactiveDismissDisabled(!newFiles.isEmpty)
    }

    // MARK: 칸

    private var fileSection: some View {
        Section {
            if let f = draft.file {
                HStack(spacing: 12) {
                    Image(systemName: f.kind == .pdf ? "doc.richtext" : "globe")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.accentText)
                        .frame(width: 40, height: 40)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.title).lineLimit(1)
                        Text(f.kind == .pdf ? "PDF·사진 도안" : (f.url ?? "")).font(.app(.caption)).foregroundStyle(Theme.muted).lineLimit(1)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Button { showImporter = true } label: { Label("파일", systemImage: "doc.badge.plus") }
                    PhotosPicker(selection: $photoItem, matching: .images) { Label("사진", systemImage: "photo") }
                    Button { webInput = ""; showWeb = true } label: { Label("웹 링크", systemImage: "link") }
                }
                .buttonStyle(ChipStyle())
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        } header: {
            HStack {
                Text("도안 파일")
                Spacer()
                if draft.file != nil {
                    HStack(spacing: 14) {
                        Menu("바꾸기") {
                            Button { showImporter = true } label: { Label("파일(PDF·이미지)", systemImage: "doc.badge.plus") }
                            PhotosPicker(selection: $photoItem, matching: .images) { Label("사진", systemImage: "photo") }
                            Button { webInput = draft.file?.url ?? ""; showWeb = true } label: { Label("웹 링크", systemImage: "link") }
                        }
                        Button("삭제", role: .destructive) { draft.file = nil }
                            .foregroundStyle(Theme.danger)
                    }
                    .font(.app(.subheadline))
                    .textCase(nil)
                }
            }
        }
    }

    private var guideSection: some View {
        Section {
            TextField("", text: $guideText,
                      prompt: Text(verbatim: "1단: 사슬5, 기둥코2, 짧은뜨기1*4 (총5)\n2단: 사슬2, 짧은뜨기1, 짧은뜨기 늘려\n3~10단: 사슬2, 짧은뜨기1*5"),
                      axis: .vertical)
                .lineLimit(4...14)
            if draft.file?.kind == .pdf {
                Button {
                    readFromFile()
                } label: {
                    HStack(spacing: 8) {
                        if reading { ProgressView().controlSize(.small) } else { Image(systemName: "doc.text.viewfinder") }
                        Text(reading ? "도안 읽는 중…" : "도안에서 단 읽기")
                    }
                }
                .disabled(reading)
            }
        } header: {
            Text("단별 안내 (선택)")
        } footer: {
            Text(verbatim: readMessage ?? guideFooter)
        }
    }

    private var guideFooter: String {
        let rows = parsed.parts.flatMap(\.rows)
        if guideText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "한 줄에 한 단씩 ‘1단: 사슬2, 짧은뜨기1*5’처럼 적어 두면, 작품을 시작할 때 단별 안내가 함께 들어가요."
        }
        if rows.isEmpty { return "단 번호를 찾지 못했어요. 줄 앞에 ‘1단:’처럼 단 번호를 붙여 주세요." }
        return "\(rows.count)줄 · \(rows.map(\.to).max() ?? 0)단까지 · 쉼표(,)마다 한 단계로 나눠요"
    }

    // MARK: 동작

    private func setFile(_ ref: PatternRef) {
        if let name = ref.fileName { newFiles.append(name) }
        draft.file = ref
        if draft.name.trimmingCharacters(in: .whitespaces).isEmpty && ref.kind == .pdf && ref.title != "사진 도안" {
            draft.name = ref.title
        }
        if ref.kind == .pdf && guideText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { readFromFile() }
    }

    private func readFromFile() {
        guard let name = draft.file?.fileName, !reading else { return }
        reading = true
        readMessage = nil
        Task {
            let r = await GuideReader.read(pdfURL: Store.patternFileURL(name))
            reading = false
            guard let part = r.parts.first else {
                readMessage = "도안에서 ‘1단:’ 같은 단 번호를 찾지 못했어요. 직접 적어 주세요."
                return
            }
            guideText = SavedPatternSheet.text(of: part.rows)
            if draft.guidePart.isEmpty, part.name != "도안" { draft.guidePart = part.name }
            if draft.yarn.isEmpty { draft.yarn = r.yarn }
            if draft.needle.isEmpty { draft.needle = r.needle }
            let others = r.parts.dropFirst()
            if !others.isEmpty && draft.notes.isEmpty {
                draft.notes = others.map { "[\($0.name)]\n" + SavedPatternSheet.text(of: $0.rows) }.joined(separator: "\n\n")
            }
            readMessage = "\(part.rows.count)줄을 읽었어요 (\(part.rows.map(\.to).max() ?? 0)단까지). 글자를 잘못 읽었을 수 있으니 도안과 비교해 보세요."
                + (others.isEmpty ? "" : " 나머지 부분(\(others.map(\.name).joined(separator: ", ")))은 메모에 넣었어요.")
        }
    }

    /// 입력한 내용을 도안함에 저장해요
    private func commit() -> Bool {
        let p = parsed
        draft.guide = p.parts.flatMap(\.rows)
        if draft.guidePart.isEmpty, let n = p.parts.first?.name, n != "도안" { draft.guidePart = n }
        if draft.guide.isEmpty { draft.guidePart = "" }
        let hasSomething = !draft.name.trimmingCharacters(in: .whitespaces).isEmpty || draft.file != nil || !draft.guide.isEmpty
        guard hasSomething else { toast.show("도안 이름이나 파일, 단별 안내 중 하나는 넣어 주세요"); return false }
        // 쓰지 않게 된 새 파일은 정리 (원래 파일은 store가 정리해요)
        newFiles.filter { $0 != draft.file?.fileName }.forEach(remove)
        newFiles = []
        store.savePattern(draft)
        isNew = false
        return true
    }

    private func remove(_ fileName: String) {
        Store.removePatternRefFile(PatternRef(kind: .pdf, title: "", fileName: fileName, url: nil))
    }
}
