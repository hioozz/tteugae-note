import SwiftUI

// MARK: - 작품 화면의 제작 기록 칸

struct RecordSection: View {
    let project: Project
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "제작 기록") {
                Button(action: onEdit) {
                    if project.hasRecord { Text("편집") } else { Label("기록하기", systemImage: "plus") }
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
            Image(systemName: symbol)
                .font(.system(size: 15))
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
            Form {
                Section {
                    LabeledContent("코 수") {
                        NumberField(placeholder: "예: 22", value: $gauge.stitches).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("단 수") {
                        NumberField(placeholder: "예: 30", value: $gauge.rows).multilineTextAlignment(.trailing)
                    }
                    TextField("바늘 (예: 4mm 대바늘)", text: $gauge.needle)
                } header: {
                    Text("게이지 (10cm 기준)")
                }

                Section {
                    ForEach($yarns) { $y in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("실 이름 (예: 메리노 울)", text: $y.name)
                            HStack(spacing: 8) {
                                TextField("색 (예: 그레이)", text: $y.color)
                                TextField("양", text: Binding(
                                    get: { y.amount == 0 ? "" : (y.amount.rounded() == y.amount ? String(Int(y.amount)) : String(y.amount)) },
                                    set: { y.amount = Double($0.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 64)
                                Picker("단위", selection: $y.unit) {
                                    Text("볼").tag("볼")
                                    Text("g").tag("g")
                                    Text("m").tag("m")
                                }
                                .labelsHidden()
                                .fixedSize()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { yarns.remove(atOffsets: $0) }
                    Button {
                        yarns.append(YarnUse())
                    } label: {
                        Label("실 추가", systemImage: "plus")
                    }
                } header: {
                    Text("사용한 실과 실제 사용량")
                } footer: {
                    Text("왼쪽으로 밀면 삭제돼요.")
                }

                Section("사이즈·수정 사항") {
                    TextEditor(text: $sizeNote).frame(minHeight: 90)
                }
            }
            .scrollDismissesKeyboard(.interactively)
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

