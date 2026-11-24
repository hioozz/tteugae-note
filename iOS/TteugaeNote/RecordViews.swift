import SwiftUI

// MARK: - 작품 화면의 제작 기록 칸

struct RecordSection: View {
    let project: Project
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "제작 기록") {
                Button(action: onEdit) {
                    if project.hasRecord { Text("편집") } else { Label("기록하기", lucide: "plus") }
                }
                .buttonStyle(ChipStyle())
            }
            if project.hasRecord {
                RecordCard(project: project)
            } else {
                HintBox(text: "사용한 실, 게이지, 사이즈 수정, 실제 사용량을 남겨 두면 다음 작품에서 그대로 참고할 수 있어요.")
            }
        }
    }
}

struct RecordCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !project.gauge.isEmpty {
                row("ruler", "게이지", [project.gauge.text])
            }
            if !project.yarnsUsed.isEmpty {
                row("circle.dotted", "사용한 실", project.yarnsUsed.map(\.text))
            }
            if !project.sizeNote.isEmpty {
                row("tshirt", "사이즈·수정", [project.sizeNote])
            }
        }
        .foregroundStyle(Theme.text)
        .card()
    }

    private func row(_ symbol: String, _ title: String, _ lines: [String]) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(lucide: symbol)
                .iconSize(18)
                .foregroundStyle(Theme.accentText)
                .frame(width: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).appFont(.caption).foregroundStyle(Theme.muted)
                ForEach(lines, id: \.self) { Text($0).appFont(.body) }
            }
        }
    }
}

// MARK: - 제작 기록 편집

struct RecordEditSheet: View {
    let projectID: String

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var gauge: Gauge
    @State private var yarns: [YarnUse]
    @State private var sizeNote: String

    init(project: Project) {
        projectID = project.id
        _gauge = State(initialValue: project.gauge)
        _yarns = State(initialValue: project.yarnsUsed.isEmpty
                       ? [YarnUse(name: project.yarn)] : project.yarnsUsed)
        _sizeNote = State(initialValue: project.sizeNote)
    }

    var body: some View {
        NavigationStack {
            AppForm {
                FormSection(title: "게이지 (10cm 기준)") {
                    InlineNumberRow(label: "코 수", placeholder: "예: 22", value: $gauge.stitches, suffix: "코")
                    InlineNumberRow(label: "단 수", placeholder: "예: 30", value: $gauge.rows, suffix: "단")
                    AppTextField("바늘 (예: 4mm 대바늘)", text: $gauge.needle)
                }

                FormSection(title: "사용한 실과 실제 사용량") {
                    ForEach($yarns) { $y in
                        if y.id != yarns.first?.id { FormDivider() }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                AppTextField("실 이름 (예: 메리노 울)", text: $y.name)
                                RemoveRowButton(label: "실 삭제") {
                                    let id = y.id
                                    yarns.removeAll { $0.id == id }
                                }
                            }
                            AppTextField("색 (예: 그레이)", text: $y.color)
                            HStack(spacing: 8) {
                                TextField("", text: Binding(
                                    get: { y.amount == 0 ? "" : (y.amount.rounded() == y.amount ? String(Int(y.amount)) : String(y.amount)) },
                                    set: { y.amount = Double($0.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0 }
                                ), prompt: Text(verbatim: "양").foregroundStyle(Theme.muted.opacity(0.75)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .fieldBox()
                                ChoiceChips(selection: $y.unit, options: [("볼", "볼"), ("g", "g"), ("m", "m")])
                            }
                        }
                    }
                    AddRowButton(title: "실 추가") { yarns.append(YarnUse()) }
                }

                FormSection(title: "사이즈·수정 사항") {
                    AppTextField("예: 소매 길이 2cm 늘림", text: $sizeNote, lines: 3...10)
                }
            }
            .navigationTitle("제작 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        store.saveRecord(projectID, gauge: gauge, yarns: yarns, sizeNote: sizeNote)
                        dismiss()
                    }
                }
            }
        }
    }
}

