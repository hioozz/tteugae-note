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
            AppForm {
                if isNew, !store.projects.filter(\.hasRecord).isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Menu {
                            ForEach(store.projects.filter(\.hasRecord).sorted { $0.updatedAt > $1.updatedAt }) { old in
                                Button(old.name) { copyRecord(from: old) }
                            }
                        } label: {
                            Label("이전 작품 기록 가져오기", lucide: "arrow.down.doc")
                                .appFont(.subheadline)
                                .foregroundStyle(Theme.text)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 7)
                                .background(Theme.surface2, in: Capsule())
                        }
                        Text(copiedFrom.map { "‘\($0)’의 실·바늘·게이지를 가져왔어요." } ?? "고른 작품의 실, 바늘, 게이지를 채워요.")
                            .appFont(.caption)
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 4)
                    }
                }
                FormSection(title: "작품") {
                    AppTextField("작품 이름 (예: 겨울 목도리)", text: $draft.name)
                    AppTextField("실 (예: 메리노 울 그레이)", text: $draft.yarn)
                    AppTextField("바늘 (예: 4.5mm 대바늘)", text: $draft.needle)
                    FormDivider()
                    InlineNumberRow(label: "목표 단수", placeholder: "선택", value: $draft.targetRows, suffix: "단")
                    InlineNumberRow(label: "시작 코 수", placeholder: "선택", value: $draft.castOn, suffix: "코")
                }

                FormSection(title: "반복 알림",
                            footer: "시작 단을 비우면 첫 알림은 ‘몇 단마다’와 같은 단에서, 횟수를 비우면 끝없이 반복해요.") {
                    ForEach($draft.reminders) { $r in
                        if r.id != draft.reminders.first?.id { FormDivider() }
                        ReminderEditor(reminder: $r) {
                            let id = r.id
                            draft.reminders.removeAll { $0.id == id }
                        }
                    }
                    AddRowButton(title: "알림 추가") {
                        draft.reminders.append(Reminder(label: "", every: 6, from: 0, times: 0))
                    }
                }

                FormSection(title: "메모") {
                    AppTextField("자유롭게 적어 두세요", text: $draft.notes, lines: 4...12)
                }

                if !isNew {
                    DangerButton(title: "이 작품 삭제") { confirmDelete = true }
                }
            }
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
    var onRemove: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ChoiceChips(selection: $reminder.kind, options: [("note", "기타"), ("inc", "늘림"), ("dec", "줄임")])
                Spacer()
                if let onRemove { RemoveRowButton(label: "알림 삭제", action: onRemove) }
            }
            AppTextField(reminder.kind == "note" ? "할 일 (예: 무늬 바꾸기)" : "할 일 (예: 양쪽 1코씩 늘리기)", text: $reminder.label)
            if reminder.kind != "note" {
                HStack(spacing: 6) {
                    Text("한 번에").appFont(.footnote).foregroundStyle(Theme.muted)
                    field("2", value: $reminder.stitches, suffix: reminder.kind == "inc" ? "코 늘림" : "코 줄임")
                }
            }
            HStack(spacing: 10) {
                field("6", value: $reminder.every, suffix: "단마다")
                field("–", value: $reminder.from, suffix: "단부터")
                field("∞", value: $reminder.times, suffix: "회")
            }
        }
    }

    private func field(_ placeholder: String, value: Binding<Int>, suffix: String) -> some View {
        HStack(spacing: 4) {
            NumberField(placeholder: placeholder, value: value)
                .multilineTextAlignment(.center)
                .fieldBox(vertical: 7)
            Text(suffix)
                .appFont(.footnote)
                .foregroundStyle(Theme.muted)
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
            AppForm {
                FormSection(footer: hasSteps ? "아래 순서를 몇 번 반복하는지 적어요. 예: 4번 반복이면 4" : "최대값을 넘으면 1로 돌아가요. 예: 8단짜리 무늬라면 8") {
                    if counter == nil {
                        ScrollView(.horizontal, showsIndicators: false) {
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
                    }
                    AppTextField("이름 (예: 무늬 반복, 코 수)", text: $name)
                    InlineNumberRow(label: hasSteps ? "반복 횟수" : "최대값", placeholder: "없음", value: $maxValue)
                }
                FormSection(title: "뜨는 순서 (선택)", footer: "순서를 적으면 ‘다음 단계’ 버튼으로 지금 어느 단계인지 따라가요.") {
                    ForEach(steps.indices, id: \.self) { i in
                        HStack(spacing: 8) {
                            Text("\(i + 1)").appFont(.caption).foregroundStyle(Theme.muted).frame(width: 18)
                            AppTextField(i == 0 ? "예: 짧은뜨기 1" : "예: 사슬뜨기 2", text: Binding(
                                get: { steps.indices.contains(i) ? steps[i] : "" },
                                set: { if steps.indices.contains(i) { steps[i] = $0 } }
                            ))
                            RemoveRowButton(label: "\(i + 1)번 단계 삭제") { steps.remove(at: i) }
                        }
                    }
                    AddRowButton(title: "단계 추가") { steps.append("") }
                    if hasSteps {
                        ToggleRow(title: "반복을 다 끝내면 단 +1", isOn: $rowOnFinish)
                    }
                }
                if !hasSteps {
                    FormSection(footer: "단을 올리거나 내리면 이 카운터도 함께 움직여요.") {
                        ToggleRow(title: "단과 연동", isOn: $linked)
                    }
                }
                if let counter {
                    InlineActionButton(title: hasSteps ? "처음부터 다시 세기" : "0부터 다시 세기", systemImage: "arrow.counterclockwise") {
                        store.resetCounter(projectID, counterID: counter.id)
                        dismiss()
                    }
                    DangerButton(title: "카운터 삭제") { confirmDelete = true }
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
            AppForm {
                FormSection {
                    ToggleRow(title: "진동", detail: "단을 셀 때 짧게 진동해요", isOn: $haptics)
                    FormDivider()
                    ToggleRow(title: "화면 켜두기", detail: "카운터 화면에서는 화면이 꺼지지 않아요", isOn: $keepAwake)
                }
                Text("작품 기록은 이 아이폰에 저장되고 아이폰 iCloud 백업에도 포함돼요. 다른 기기로 옮길 땐 홈 화면 맨 아래 ‘백업 내보내기’를 쓰세요.")
                    .appFont(.caption)
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 4)
                Text("버전 \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .appFont(.caption)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Theme.bg)
    }
}
