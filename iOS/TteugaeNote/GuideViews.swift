import SwiftUI

// MARK: - 지금 단의 도안 안내

struct GuideCard: View {
    let project: Project
    let onMove: (_ delta: Int) -> Void
    let onReread: (() -> Void)?
    let onEdit: () -> Void
    let onClear: () -> Void
    var onSaveToLibrary: (() -> Void)? = nil

    @State private var showAll = false

    private var rowNumber: Int { project.guideRowNumber }
    private var guide: GuideRow? { project.guideRow(at: rowNumber) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(rowNumber)단 도안").appFont(.headline)
                if let g = guide, g.from != g.to {
                    Text("\(g.label) 같은 내용").appFont(.caption).foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 4)
                if let g = guide, g.total > 0 {
                    Pill(text: "총 \(g.total)코", fg: Theme.text, bg: Theme.surface2).appFont(.caption)
                }
                Menu {
                    Button(action: onEdit) { Label("안내 고치기", systemImage: "pencil") }
                    if let onReread { Button(action: onReread) { Label("도안에서 다시 읽기", systemImage: "doc.text.viewfinder") } }
                    if let onSaveToLibrary { Button(action: onSaveToLibrary) { Label("도안함에 저장", systemImage: "book") } }
                    Divider()
                    Button(role: .destructive, action: onClear) { Label("안내 지우기", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis").frame(width: 32, height: 28).contentShape(Rectangle())
                }
                .foregroundStyle(Theme.muted)
                .accessibilityLabel("도안 안내 설정")
            }

            if let g = guide {
                let steps = g.steps
                let current = project.currentGuideStep
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            ZStack {
                                Circle().fill(i < current ? Theme.accentText.opacity(0.45) : i == current ? Theme.accentText : Theme.surface2)
                                if i < current {
                                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.surface)
                                } else {
                                    Text("\(i + 1)").appFont(size: 11, relativeTo: .caption2)
                                        .foregroundStyle(i == current ? Theme.surface : Theme.muted)
                                }
                            }
                            .frame(width: 20, height: 20)
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                            Text(s)
                                .appFont(size: i == current ? 22 : 17, relativeTo: i == current ? .title3 : .body)
                                .foregroundStyle(i == current ? Theme.text : Theme.muted)
                                .strikethrough(i < current, color: Theme.muted.opacity(0.5))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(rowNumber)단, 지금 \(steps[min(current, steps.count - 1)]), 단계 \(current + 1)/\(steps.count)")

                HStack(spacing: 8) {
                    Button { onMove(-1) } label: {
                        Image(systemName: "arrow.uturn.backward").frame(width: 52, height: 52)
                    }
                    .buttonStyle(PressStyle(bg: Theme.surface2, fg: Theme.text, radius: 16))
                    .disabled(current == 0)
                    .accessibilityLabel("한 단계 뒤로")

                    Button { onMove(1) } label: {
                        Label(current + 1 >= steps.count ? "\(rowNumber)단 끝 · 다음 단으로" : "다음 단계",
                              systemImage: current + 1 >= steps.count ? "checkmark" : "chevron.right")
                            .labelStyle(TrailingIconLabelStyle())
                            .appFont(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(PressStyle(bg: Theme.accent, fg: Theme.accentInk, radius: 16))
                }
            } else {
                Text(rowNumber > project.guideMaxRow
                     ? "도안 안내는 \(project.guideMaxRow)단까지예요. 다 떴어요!"
                     : "\(rowNumber)단은 도안에 안내가 없어요.")
                    .appFont(.subheadline)
                    .foregroundStyle(Theme.muted)
            }

            DisclosureGroup(isExpanded: $showAll) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(project.guide) { g in
                        let isNow = g.from <= rowNumber && rowNumber <= g.to
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(g.label).monospacedDigit().frame(width: 62, alignment: .leading)
                                .foregroundStyle(isNow ? Theme.accentText : Theme.muted)
                            Text(g.text + (g.total > 0 ? " (총 \(g.total)코)" : ""))
                                .foregroundStyle(isNow ? Theme.text : Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .appFont(.subheadline)
                    }
                }
                .padding(.top, 6)
            } label: {
                Text(project.guidePart.isEmpty ? "전체 단 보기" : "\(project.guidePart) 전체 보기")
                    .appFont(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            .tint(Theme.muted)
        }
        .foregroundStyle(Theme.text)
        .card()
    }
}

// MARK: - 도안에서 읽은 안내 확인

struct GuideImportSheet: View {
    let projectID: String
    let result: GuideParser.Result
    var editing = false
    var manual = false          // 처음부터 직접 입력

    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss

    @State private var partIndex = 0
    @State private var rows: [GuideRow] = []
    @State private var setTarget = true
    @State private var fillYarn = true
    @State private var noteOthers = true
    @State private var bulk = ""
    @State private var bulkMessage: String?
    @State private var partName = ""

    private var project: Project? { store.project(projectID) }
    private var maxRow: Int { rows.map(\.to).max() ?? 0 }
    private var others: [GuideParser.Part] { result.parts.enumerated().filter { $0.offset != partIndex }.map(\.element) }
    private var canFill: Bool {
        guard let p = project else { return false }
        return (!result.yarn.isEmpty && p.yarn.isEmpty) || (!result.needle.isEmpty && p.needle.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !editing {
                    Section {
                        if result.parts.count > 1 {
                            Picker("셀 부분", selection: $partIndex) {
                                ForEach(result.parts.indices, id: \.self) { i in
                                    Text("\(result.parts[i].name) (\(result.parts[i].rows.map(\.to).max() ?? 0)단)").tag(i)
                                }
                            }
                        }
                    } header: {
                        Text("도안에서 찾았어요")
                    } footer: {
                        Text("글자를 잘못 읽었을 수 있어요. 도안과 한 번 비교해 보고 고쳐 주세요. 쉼표(,)마다 한 단계로 나눠서 보여 줘요.")
                    }
                }

                if editing || manual {
                    Section {
                        TextField("", text: $bulk, prompt: Text(verbatim: "1단: 사슬5, 기둥코2, 짧은뜨기1*4 (총5)\n2단: 사슬2, 짧은뜨기1, 짧은뜨기 늘려\n3~10단: 사슬2, 짧은뜨기1*5"), axis: .vertical)
                            .lineLimit(3...10)
                        Button {
                            splitBulk()
                        } label: {
                            Label("단별로 나누기", systemImage: "text.line.first.and.arrowtriangle.forward")
                        }
                        .disabled(bulk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } header: {
                        Text("글로 한꺼번에 넣기")
                    } footer: {
                        Text(verbatim: bulkMessage ?? "한 줄에 한 단씩 ‘1단: 사슬2, 짧은뜨기1*5’, ‘3~10단: …’처럼 적거나 붙여 넣고 나누기를 누르세요. 아래에서 한 단씩 적어도 돼요.")
                    }
                }

                Section {
                    ForEach($rows) { $r in
                        GuideRowEditor(row: $r)
                    }
                    .onDelete { rows.remove(atOffsets: $0) }
                    Button {
                        let n = maxRow + 1
                        rows.append(GuideRow(from: n, to: n, text: ""))
                    } label: {
                        Label("단 추가", systemImage: "plus")
                    }
                } header: {
                    Text("단별 안내")
                }

                Section {
                    if maxRow > 0 {
                        Toggle("목표 단수를 \(maxRow)단으로", isOn: $setTarget)
                    }
                    if !editing && canFill {
                        Toggle(isOn: $fillYarn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("실·바늘 칸 채우기")
                                Text([result.yarn, result.needle].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .appFont(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                    if !editing && !others.isEmpty {
                        Toggle(isOn: $noteOthers) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("나머지 부분은 메모에 붙이기")
                                Text(others.map(\.name).joined(separator: ", "))
                                    .appFont(.caption).foregroundStyle(Theme.muted)
                            }
                        }
                    }
                }
            }
            .navigationTitle(manual ? "도안 직접 입력" : editing ? "도안 안내 고치기" : "도안 단 읽기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing && !manual ? "저장" : "적용") { apply() }
                        .disabled(rows.allSatisfy { $0.text.trimmingCharacters(in: .whitespaces).isEmpty })
                }
            }
            .onAppear { loadRows() }
            .onChange(of: partIndex) { _, _ in loadRows() }
        }
    }

    private func splitBulk() {
        let lines = bulk.components(separatedBy: .newlines).enumerated().map { GuideParser.Line(text: $1, y: Double($0)) }
        let parsed = GuideParser.parse(lines)
        let found = parsed.parts.flatMap(\.rows)
        if found.isEmpty {
            bulkMessage = "단 번호를 찾지 못했어요. ‘1단: 사슬2, 짧은뜨기1*5’처럼 줄 앞에 단 번호를 붙여 주세요."
            return
        }
        rows = found
        if partName.isEmpty, let n = parsed.parts.first?.name, n != "도안" { partName = n }
        bulkMessage = "\(found.count)줄로 나눴어요 (\(maxRow)단까지). 아래에서 확인하고 고쳐 주세요."
        bulk = ""
        setTarget = true
    }

    private func loadRows() {
        if manual {
            if rows.isEmpty { rows = [GuideRow(from: 1, to: 1, text: "")] }
            setTarget = true
            return
        }
        if editing { rows = project?.guide ?? []; setTarget = false; return }
        rows = result.parts.indices.contains(partIndex) ? result.parts[partIndex].rows : []
        setTarget = true
    }

    private func apply() {
        let part = manual ? partName : editing ? (project?.guidePart ?? "") : (result.parts.indices.contains(partIndex) ? result.parts[partIndex].name : "")
        var note: String?
        if !editing && noteOthers && !others.isEmpty {
            note = others.map { o in
                "[\(o.name)]\n" + o.rows.map { $0.from == 1 && o.rows.count == 1 ? $0.text : "\($0.label): \($0.text)" }.joined(separator: "\n")
            }.joined(separator: "\n\n")
        }
        let fill = !editing && fillYarn
        store.setGuide(projectID, rows: rows, part: part,
                       targetRows: setTarget ? maxRow : nil,
                       yarn: fill ? result.yarn : nil,
                       needle: fill ? result.needle : nil,
                       extraNote: note)
        Haptics.success()
        toast.show(editing && !manual ? "도안 안내를 고쳤어요" : "\(part.isEmpty ? "" : part + " ")\(maxRow)단 안내를 넣었어요")
        dismiss()
    }
}

private struct GuideRowEditor: View {
    @Binding var row: GuideRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                NumberField(placeholder: "단", value: Binding(get: { row.from }, set: { row.from = max(1, $0); if row.to < row.from { row.to = row.from } }))
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 4)
                    .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 8))
                Text("~").foregroundStyle(Theme.muted)
                NumberField(placeholder: "단", value: Binding(get: { row.to }, set: { row.to = $0 }))
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 4)
                    .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 8))
                Text("단").foregroundStyle(Theme.muted)
                Spacer()
                if row.total > 0 {
                    Text("총 \(row.total)코").appFont(.caption).foregroundStyle(Theme.muted)
                }
            }
            TextField("", text: $row.text, prompt: Text(verbatim: "뜨는 방법 (예: 사슬2, 짧은뜨기1*5)"), axis: .vertical)
                .lineLimit(1...4)
            let steps = row.steps
            if steps.count > 1 {
                Text(steps.joined(separator: "  →  "))
                    .appFont(.caption)
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(.vertical, 2)
    }
}
