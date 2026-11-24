import SwiftUI

// MARK: - 작품 만들기 / 수정

struct ProjectFormView: View {
    let project: Project?
    var onCreate: ((String) -> Void)?

    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Project
    @State private var confirmDelete = false
    @State private var copiedFrom: String?

    init(project: Project?, onCreate: ((String) -> Void)? = nil) {
        self.project = project
        self.onCreate = onCreate
        _draft = State(initialValue: project ?? Project(name: ""))
    }

    private var isNew: Bool { project == nil }
    private var canSave: Bool { !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                if isNew, !store.projects.filter(\.hasRecord).isEmpty {
                    Section {
                        Menu {
                            ForEach(store.projects.filter(\.hasRecord).sorted { $0.updatedAt > $1.updatedAt }) { old in
                                Button(old.name) { copyRecord(from: old) }
                            }
                        } label: {
                            Label("이전 작품 기록 가져오기", systemImage: "arrow.down.doc")
                        }
                    } footer: {
                        Text(copiedFrom.map { "‘\($0)’의 실·바늘·게이지를 가져왔어요." } ?? "고른 작품의 실, 바늘, 게이지를 채워요.")
                    }
                }
                Section("작품") {
                    TextField("작품 이름 (예: 겨울 목도리)", text: $draft.name)
                    TextField("실 (예: 메리노 울 그레이)", text: $draft.yarn)
                    TextField("바늘 (예: 4.5mm 대바늘)", text: $draft.needle)
                    LabeledContent("목표 단수") {
                        NumberField(placeholder: "선택", value: $draft.targetRows)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("시작 코 수") {
                        NumberField(placeholder: "선택", value: $draft.castOn)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    ForEach($draft.reminders) { $r in
                        ReminderEditor(reminder: $r)
                    }
                    .onDelete { draft.reminders.remove(atOffsets: $0) }
                    Button {
                        draft.reminders.append(Reminder(label: "", every: 6, from: 0, times: 0))
                    } label: {
                        Label("알림 추가", systemImage: "plus")
                    }
                } header: {
                    Text("반복 알림")
                } footer: {
                    Text("시작 단을 비우면 첫 알림은 ‘몇 단마다’와 같은 단에서, 횟수를 비우면 끝없이 반복해요. 왼쪽으로 밀면 삭제돼요.")
                }

                Section("메모") {
                    TextEditor(text: $draft.notes).frame(minHeight: 100)
                }

                if !isNew {
                    Section {
                        Button("이 작품 삭제", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNew ? "새 작품" : "작품 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "시작" : "저장") { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("‘\(draft.name)’ 작품을 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    store.deleteProject(draft.id)
                    toast.show("작품을 삭제했어요")
                    dismiss()
                }
            } message: {
                Text("삭제하면 되돌릴 수 없어요.")
            }
        }
    }

    /// 이전 작품의 실·바늘·게이지를 새 작품에 채워요
    private func copyRecord(from old: Project) {
        let yarn = old.yarnsUsed.first.map { [$0.name, $0.color].filter { !$0.isEmpty }.joined(separator: " ") } ?? ""
        draft.yarn = yarn.isEmpty ? old.yarn : yarn
        draft.needle = old.gauge.needle.isEmpty ? old.needle : old.gauge.needle
        draft.gauge = old.gauge
        copiedFrom = old.name
    }

    private func save() {
        let id = store.saveProject(draft)
        if isNew { onCreate?(id) } else { toast.show("저장했어요") }
        dismiss()
    }
}

struct ReminderEditor: View {
    @Binding var reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("종류", selection: $reminder.kind) {
                Text("기타").tag("note")
                Text("늘림").tag("inc")
                Text("줄임").tag("dec")
            }
            .pickerStyle(.segmented)
            TextField(reminder.kind == "note" ? "할 일 (예: 무늬 바꾸기)" : "할 일 (예: 양쪽 1코씩 늘리기)", text: $reminder.label)
            if reminder.kind != "note" {
                HStack(spacing: 4) {
                    Text("한 번에").appFont(.footnote).foregroundStyle(.secondary)
                    field("2", value: $reminder.stitches, suffix: reminder.kind == "inc" ? "코 늘림" : "코 줄임")
                }
            }
            HStack(spacing: 10) {
                field("6", value: $reminder.every, suffix: "단마다")
                field("–", value: $reminder.from, suffix: "단부터")
                field("∞", value: $reminder.times, suffix: "회")
            }
        }
        .padding(.vertical, 4)
    }

    private func field(_ placeholder: String, value: Binding<Int>, suffix: String) -> some View {
        HStack(spacing: 4) {
            NumberField(placeholder: placeholder, value: value)
                .multilineTextAlignment(.center)
                .padding(.vertical, 6)
                .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(suffix)
                .appFont(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}

// MARK: - 보조 카운터 추가 / 설정

struct CounterEditSheet: View {
    let projectID: String
    let counter: SubCounter?

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var maxValue: Int
    @State private var linked: Bool
    @State private var steps: [String]
    @State private var rowOnFinish: Bool
    @State private var confirmDelete = false

    init(projectID: String, counter: SubCounter?) {
        self.projectID = projectID
        self.counter = counter
        _name = State(initialValue: counter?.name ?? "")
        _maxValue = State(initialValue: counter?.max ?? 0)
        _linked = State(initialValue: counter?.linked ?? false)
        _steps = State(initialValue: counter?.steps ?? [])
        _rowOnFinish = State(initialValue: counter?.rowOnFinish ?? false)
    }

    private var hasSteps: Bool { steps.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// 자주 쓰는 보조 카운터를 한 번에 채워요
    private func preset(_ title: String, linked isLinked: Bool) -> some View {
        Button(title) {
            name = title
            linked = isLinked
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if counter == nil {
                        HStack(spacing: 8) {
                            preset("무늬 반복", linked: true)
                            preset("코 수", linked: false)
                            preset("모티브", linked: false)
                            Button("순서 반복") {
                                name = "순서 반복"
                                linked = false
                                if steps.isEmpty { steps = ["", ""] }
                            }
                        }
                        .buttonStyle(ChipStyle())
                    }
                    TextField("이름 (예: 무늬 반복, 코 수)", text: $name)
                    LabeledContent(hasSteps ? "반복 횟수" : "최대값") {
                        NumberField(placeholder: "없음", value: $maxValue)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text(hasSteps ? "아래 순서를 몇 번 반복하는지 적어요. 예: 4번 반복이면 4" : "최대값을 넘으면 1로 돌아가요. 예: 8단짜리 무늬라면 8")
                }
                Section {
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(spacing: 10) {
                            Text("\(i + 1)").appFont(.caption).foregroundStyle(.secondary).frame(width: 18)
                            TextField(i == 0 ? "예: 짧은뜨기 1" : "예: 사슬뜨기 2", text: $steps[i])
                        }
                    }
                    .onDelete { steps.remove(atOffsets: $0) }
                    .onMove { steps.move(fromOffsets: $0, toOffset: $1) }
                    Button { steps.append("") } label: { Label("단계 추가", systemImage: "plus") }
                    if hasSteps {
                        Toggle("반복을 다 끝내면 단 +1", isOn: $rowOnFinish)
                    }
                } header: {
                    Text("뜨는 순서 (선택)")
                } footer: {
                    Text("순서를 적으면 ‘다음 단계’ 버튼으로 지금 어느 단계인지 따라가요. 왼쪽으로 밀면 삭제돼요.")
                }
                if !hasSteps {
                    Section {
                        Toggle("단과 연동", isOn: $linked)
                    } footer: {
                        Text("단을 올리거나 내리면 이 카운터도 함께 움직여요.")
                    }
                }
                if let counter {
                    Section {
                        Button(hasSteps ? "처음부터 다시 세기" : "0부터 다시 세기") {
                            store.resetCounter(projectID, counterID: counter.id)
                            dismiss()
                        }
                        Button("카운터 삭제", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(counter == nil ? "보조 카운터 추가" : "카운터 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(counter == nil ? "추가" : "저장") {
                        store.saveCounter(projectID, counterID: counter?.id, name: String(trimmed.prefix(30)),
                                          max: maxValue, linked: linked, steps: steps, rowOnFinish: rowOnFinish)
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
            .confirmationDialog("‘\(counter?.name ?? "")’ 카운터를 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    if let counter { store.deleteCounter(projectID, counterID: counter.id) }
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - 설정

struct SettingsView: View {
    @AppStorage("haptics") private var haptics = true
    @AppStorage("keepAwake") private var keepAwake = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("진동", isOn: $haptics)
                    Toggle("카운터 화면 켜두기", isOn: $keepAwake)
                } footer: {
                    Text("작품 기록은 이 아이폰에 저장되고 아이폰 iCloud 백업에도 포함돼요. 다른 기기로 옮길 땐 ‘백업 내보내기’를 쓰세요.")
                }
                Section("정보") {
                    LabeledContent("버전", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
