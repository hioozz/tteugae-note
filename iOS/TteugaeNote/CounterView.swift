import SwiftUI
import UIKit
import PhotosUI

struct CounterView: View {
    let projectID: String

    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast
    @Environment(\.dismiss) private var dismiss
    @AppStorage("keepAwake") private var keepAwake = true

    @State private var showEdit = false
    @State private var showSetRow = false
    @State private var rowInput = ""
    @State private var addingCounter = false
    @State private var editingCounter: SubCounter?
    @State private var notes = ""
    @State private var showPattern = false
    @State private var showPDFImporter = false
    @State private var showWebInput = false
    @State private var webInput = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showPause = false
    @State private var pauseNote = ""
    @State private var showAddChange = false
    @State private var changeText = ""
    @State private var showRecord = false
    @State private var showMaterials = false
    @State private var readingGuide = false
    @State private var guideDraft: GuideDraft?

    var body: some View {
        if let p = store.project(projectID) {
            content(p)
        } else {
            EmptyStateView(title: "작품을 찾을 수 없어요", message: "지워졌거나 옮겨진 작품이에요.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bg.ignoresSafeArea())
        }
    }

    private func content(_ p: Project) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if p.isPaused {
                    pausedBanner(p).padding(.bottom, 12)
                }
                if !p.meta.isEmpty {
                    Text(p.meta).font(.app(.subheadline)).foregroundStyle(Theme.muted)
                }
                let hasGuide = !p.guide.isEmpty
                if hasGuide {
                    compactNumber(p)
                } else {
                    mainNumber(p)
                    tapButtons
                    subActions(p)
                }
                let hits = p.hits(at: p.row)
                if !hits.isEmpty {
                    alertBox(row: p.row, hits: hits).padding(.top, 14)
                }
                if hasGuide {
                    GuideCard(project: p,
                              onMove: moveGuide,
                              onReread: p.pattern?.kind == .pdf ? { readGuide(auto: false) } : nil,
                              onEdit: { guideDraft = GuideDraft(result: GuideParser.Result(), editing: true) },
                              onClear: {
                                  store.setGuide(projectID, rows: [], part: "")
                                  toast.show("도안 안내를 지웠어요")
                              },
                              onSaveToLibrary: saveToLibrary)
                        .padding(.top, 14)
                    compactRowButtons(p).padding(.top, 12)
                }
                PatternSection(project: p,
                               photoItem: $photoItem,
                               onOpen: { showPattern = true },
                               onPickPDF: { showPDFImporter = true },
                               onAddWeb: { webInput = p.pattern?.url ?? ""; showWebInput = true },
                               onRemove: { store.setPattern(projectID, nil) },
                               onSaveToLibrary: saveToLibrary)
                    .padding(.top, 30)
                if p.guide.isEmpty {
                    guideButtons(p).padding(.top, 10)
                }
                MaterialsSection(project: p) { showMaterials = true }.padding(.top, 30)
                remindersSection(p).padding(.top, 30)
                countersSection(p).padding(.top, 30)
                changesSection(p).padding(.top, 30)
                RecordSection(project: p) { showRecord = true }.padding(.top, 30)
                PhotosSection(project: p).padding(.top, 30)
                notesSection.padding(.top, 30)
                statusButtons(p).padding(.top, 30)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(p.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("편집") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: afterEdit) { ProjectFormView(project: p) }
        .sheet(isPresented: $addingCounter) { CounterEditSheet(projectID: projectID, counter: nil) }
        .sheet(isPresented: $showRecord) { RecordEditSheet(project: p) }
        .sheet(isPresented: $showMaterials) { MaterialPickerSheet(project: p) }
        .sheet(item: $editingCounter) { CounterEditSheet(projectID: projectID, counter: $0) }
        .sheet(item: $guideDraft) { GuideImportSheet(projectID: projectID, result: $0.result, editing: $0.editing, manual: $0.manual) }
        .alert("잠시 멈출까요?", isPresented: $showPause) {
            TextField("어디까지 했는지 (예: 왼쪽 소매 12단)", text: $pauseNote)
            Button("취소", role: .cancel) {}
            Button("멈춤") {
                store.pause(projectID, note: pauseNote)
                toast.show("잠시 멈췄어요. 목록의 ‘멈춤’에 있어요")
            }
        } message: {
            Text("다시 시작할 때 이 메모와 단수·바늘이 함께 보여요.")
        }
        .alert("변경 기록 추가", isPresented: $showAddChange) {
            TextField("바꾼 내용 (예: 소매 5단 더 길게)", text: $changeText)
            Button("취소", role: .cancel) {}
            Button("추가") { store.addChange(projectID, text: changeText) }
        } message: {
            Text("지금 \(p.row)단으로 함께 기록돼요.")
        }
        .alert("현재 단 입력", isPresented: $showSetRow) {
            TextField("단", text: $rowInput).keyboardType(.numberPad)
            Button("취소", role: .cancel) {}
            Button("적용") {
                if let n = Int(rowInput.filter(\.isNumber)) {
                    withAnimation(.snappy(duration: 0.2)) { store.setRow(projectID, n) }
                }
            }
        } message: {
            Text("몇 단째인가요?")
        }
        .navigationDestination(isPresented: $showPattern) { PatternScreen(projectID: projectID) }
        .fileImporter(isPresented: $showPDFImporter, allowedContentTypes: [.pdf, .image]) { result in
            guard case .success(let url) = result else { return }
            do {
                if PatternImport.imageExtensions.contains(url.pathExtension.lowercased()) {
                    guard let data = PatternImport.pdfData(fromImageFile: url) else { throw CocoaError(.fileReadCorruptFile) }
                    try store.importPDFData(projectID, data: data, title: url.deletingPathExtension().lastPathComponent)
                } else {
                    try store.importPDF(projectID, from: url)
                }
                readGuide(auto: true)
            } catch {
                toast.show("도안을 불러오지 못했어요")
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                defer { photoItem = nil }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let pdf = PatternImport.pdfData(fromImage: image) else {
                    toast.show("사진을 불러오지 못했어요")
                    return
                }
                do {
                    try store.importPDFData(projectID, data: pdf, title: "사진 도안")
                    readGuide(auto: true)
                } catch {
                    toast.show("사진을 저장하지 못했어요")
                }
            }
        }
        .alert("웹 도안 링크", isPresented: $showWebInput) {
            TextField("https://", text: $webInput)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("취소", role: .cancel) {}
            Button("추가") {
                if store.setWebPattern(projectID, webInput) {
                    showPattern = true
                } else {
                    toast.show("링크 주소를 확인해 주세요")
                }
            }
        } message: {
            Text("도안이 있는 웹 페이지 주소를 붙여 넣으세요.")
        }
        .onAppear {
            notes = p.notes
            UIApplication.shared.isIdleTimerDisabled = keepAwake
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: notes) { _, new in store.setNotes(projectID, new) }
    }

    // MARK: 큰 숫자

    private func mainNumber(_ p: Project) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text("현재 단")
                if p.isDone { Pill(text: "완성", fg: Theme.sage, bg: Theme.sageSoft).font(.app(.caption)) }
            }
            .font(.app(.subheadline))
            .foregroundStyle(Theme.muted)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(p.row)")
                    .font(.app(size: 120, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(p.row)))
                Text("단")
                    .font(.app(.title2))
                    .foregroundStyle(Theme.muted)
            }
            .foregroundStyle(Theme.text)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("현재 \(p.row)단")

            if let pr = p.progress {
                Text(targetText(p, progress: pr))
                    .font(.app(.subheadline))
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
                ProgressBar(value: pr)
                    .frame(maxWidth: 280)
                    .padding(.top, 4)
            }
            Text("오늘 \(p.log[Store.todayKey()] ?? 0)단 떴어요")
                .font(.app(.subheadline))
                .foregroundStyle(Theme.muted)
                .padding(.top, 8)
            progressSummary(p)
        }
        .padding(.vertical, 12)
    }

    /// 도안 안내가 있을 때: 단 숫자는 작게, 안내 카드가 주인공
    private func compactNumber(_ p: Project) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(p.guideRowNumber)")
                    .font(.app(size: 56, relativeTo: .largeTitle))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(p.guideRowNumber)))
                Text(p.targetRows > 0 ? "/ \(p.targetRows)단" : "단째")
                    .font(.app(.title3))
                    .foregroundStyle(Theme.muted)
                if p.isDone { Pill(text: "완성", fg: Theme.sage, bg: Theme.sageSoft).font(.app(.caption)) }
            }
            .foregroundStyle(Theme.text)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("지금 \(p.guideRowNumber)단째")
            if let pr = p.progress {
                ProgressBar(value: pr).frame(maxWidth: 280)
            }
            Text("오늘 \(p.log[Store.todayKey()] ?? 0)단 떴어요")
                .font(.app(.subheadline))
                .foregroundStyle(Theme.muted)
            progressSummary(p)
        }
        .padding(.top, 8)
    }

    /// 안내 카드 아래의 작은 단 버튼: 반복 구간을 단계 없이 넘기거나 단을 바로잡을 때
    private func compactRowButtons(_ p: Project) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Button { changeRow(-1) } label: {
                    Image(systemName: "minus").frame(width: 52, height: 48)
                }
                .buttonStyle(PressStyle(bg: Theme.surface2, fg: Theme.text, radius: 16))
                .accessibilityLabel("1단 빼기")
                Button {
                    if p.guideRow(at: p.guideRowNumber) != nil { moveGuide(1, wholeRow: true) } else { changeRow(1) }
                } label: {
                    Text("+1단 · 단계 없이 이 단 끝")
                        .font(.app(.subheadline))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(PressStyle(bg: Theme.surface2, fg: Theme.text, radius: 16))
                .accessibilityLabel("1단 더하기")
            }
            subActions(p).padding(.top, -12)
        }
    }

    /// 늘림·줄임 횟수와 지금 코 수를 한눈에
    @ViewBuilder
    private func progressSummary(_ p: Project) -> some View {
        let shaping = p.reminders.filter { $0.kindLabel != nil }
        let stitches = p.stitchCount(at: p.row)
        if !shaping.isEmpty || stitches != nil {
            HStack(spacing: 6) {
                ForEach(shaping) { r in
                    let done = r.doneCount(at: p.row)
                    Pill(text: "\(r.kindLabel ?? "") \(done)\(r.times > 0 ? "/\(r.times)" : "")회",
                         fg: r.kind == "inc" ? Theme.sage : Theme.accentText,
                         bg: r.kind == "inc" ? Theme.sageSoft : Theme.accentSoft)
                }
                if let stitches {
                    Pill(text: "지금 \(stitches)코", fg: Theme.text, bg: Theme.surface2)
                }
            }
            .font(.app(.subheadline))
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
        }
    }

    private func targetText(_ p: Project, progress: Double) -> String {
        var s = "목표 \(p.targetRows)단 · \(Int((progress * 100).rounded()))%"
        if p.row < p.targetRows { s += " · \(p.targetRows - p.row)단 남음" }
        return s
    }

    // MARK: 버튼

    private var tapButtons: some View {
        HStack(spacing: 12) {
            Button { changeRow(-1) } label: {
                Image(systemName: "minus")
                    .font(.system(size: 30))
                    .frame(width: 96, height: 128)
            }
            .buttonStyle(PressStyle(bg: Theme.surface2, fg: Theme.text))
            .accessibilityLabel("1단 빼기")

            Button { changeRow(1) } label: {
                Text("+1단")
                    .font(.app(size: 32, relativeTo: .title))
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
            }
            .buttonStyle(PressStyle(bg: Theme.accent, fg: Theme.accentInk))
            .shadow(color: Theme.accent.opacity(0.3), radius: 12, y: 6)
            .accessibilityLabel("1단 더하기")
        }
        .padding(.top, 18)
    }

    private func subActions(_ p: Project) -> some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { _ = store.undo(projectID) }
                Haptics.light()
                toast.show("되돌렸어요")
            } label: {
                Label("되돌리기", systemImage: "arrow.uturn.backward")
            }
            .disabled(!store.canUndo(projectID))

            Button("단 직접 입력") {
                rowInput = "\(p.row)"
                showSetRow = true
            }
        }
        .buttonStyle(ChipStyle())
        .padding(.top, 12)
    }

    private func alertBox(row: Int, hits: [ReminderHit]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.fill").padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(row)단에서 할 일").font(.app(.headline))
                ForEach(hits) { h in
                    Text("• " + h.reminder.label + (h.reminder.times > 0 ? " (\(h.index + 1)/\(h.reminder.times)회)" : ""))
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.warnInk)
        .card(fill: Theme.warnBg, stroke: Theme.warnLine)
        .accessibilityElement(children: .combine)
    }

    // MARK: 섹션

    private func remindersSection(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "반복 알림") {
                Button { showEdit = true } label: {
                    if p.reminders.isEmpty { Label("추가", systemImage: "plus") } else { Text("편집") }
                }
                .buttonStyle(ChipStyle())
            }
            if p.reminders.isEmpty {
                HintBox(text: "“6단마다 양쪽 1코 늘리기 × 8회”처럼 정해 두면 그 단에 도착했을 때 알려 드려요.")
            } else {
                ForEach(p.reminders) { ReminderRow(reminder: $0, row: p.row) }
            }
        }
    }

    private func countersSection(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "보조 카운터") {
                Button { addingCounter = true } label: { Label("추가", systemImage: "plus") }
                    .buttonStyle(ChipStyle())
            }
            if p.counters.isEmpty {
                HintBox(text: "무늬 반복, 코 수처럼 따로 셀 것을 추가하세요. ‘단과 연동’을 켜면 단을 올릴 때 함께 올라가요. 뜨는 순서를 적어 두면 지금 몇 번째 반복의 어느 단계인지도 알려 줘요.")
            } else {
                ForEach(p.counters) { c in
                    if c.isSequence {
                        SequenceCounterCard(counter: c,
                                            onMove: { moveStep(c, by: $0, wholeRound: $1) },
                                            onEdit: { editingCounter = c })
                    } else {
                        CounterRow(counter: c, row: p.row,
                                   onChange: { changeCounter(c, by: $0) },
                                   onEdit: { editingCounter = c })
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "메모") { EmptyView() }
            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
                .padding(10)
                .overlay(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("도안 페이지, 바꾼 부분, 기억할 점…")
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .background(WobblyRoundedRect(cornerRadius: 16).fill(Theme.surface))
                .overlay(WobblyRoundedRect(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
        }
    }

    /// 멈춘 작품을 다시 열었을 때: 어디까지 했는지 한눈에
    private func pausedBanner(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "pause.circle")
                Text("잠시 멈춘 작품이에요").font(.app(.headline))
                Spacer(minLength: 0)
                if let d = p.pausedDate {
                    Text(d, format: .dateTime.month().day()).font(.app(.caption))
                }
            }
            if !p.resumeNote.isEmpty {
                Text("“\(p.resumeNote)”").font(.app(.body))
            }
            Text([ "\(p.row)단", p.needle.isEmpty ? nil : p.needle, p.pattern?.kind == .pdf ? "도안 \((p.pattern?.page ?? 0) + 1)쪽" : nil ]
                    .compactMap { $0 }.joined(separator: " · "))
                .font(.app(.subheadline))
                .opacity(0.8)
            Button {
                store.resume(projectID)
                Haptics.success()
                toast.show("다시 시작해요!")
            } label: {
                Label("다시 시작", systemImage: "play.fill")
                    .font(.app(.body))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .buttonStyle(WobblyPressStyle(bg: Theme.accent, fg: Theme.accentInk))
            .padding(.top, 2)
        }
        .foregroundStyle(Theme.warnInk)
        .card(fill: Theme.warnBg, stroke: Theme.warnLine)
    }

    private func changesSection(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "변경 기록") {
                Button {
                    changeText = ""
                    showAddChange = true
                } label: { Label("추가", systemImage: "plus") }
                .buttonStyle(ChipStyle())
            }
            if p.changes.isEmpty {
                HintBox(text: "도안과 다르게 바꾼 점을 남겨 두세요. 몇 단에서 바꿨는지도 함께 기록돼요.")
            } else {
                ForEach(p.changes) { c in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.text).font(.app(.body))
                            Text("\(c.row)단 · \(c.dateValue.formatted(.dateTime.month().day()))")
                                .font(.app(.caption))
                                .foregroundStyle(Theme.muted)
                        }
                        Spacer(minLength: 4)
                        Button {
                            store.deleteChange(projectID, changeID: c.id)
                        } label: {
                            Image(systemName: "trash").frame(width: 32, height: 32)
                        }
                        .foregroundStyle(Theme.muted)
                        .accessibilityLabel("이 변경 기록 삭제")
                    }
                    .foregroundStyle(Theme.text)
                    .card()
                }
            }
        }
    }

    /// 아래쪽 상태 버튼: 진행 중이면 ‘잠시 멈춤’과 ‘완성’
    @ViewBuilder
    private func statusButtons(_ p: Project) -> some View {
        VStack(spacing: 10) {
            if p.status == "active" {
                Button {
                    pauseNote = p.resumeNote
                    showPause = true
                } label: {
                    Label("잠시 멈춤", systemImage: "pause")
                        .font(.app(.headline))
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .foregroundStyle(Theme.warnInk)
                        .background(WobblyRoundedRect(cornerRadius: 16).fill(Theme.warnBg))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            doneButton(p)
        }
    }

    private func doneButton(_ p: Project) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return Button {
            let hadDeducted = p.deducted
            let taken = store.setDone(projectID, !p.isDone)
            if !p.isDone {
                Haptics.success()
                let used = taken.compactMap { l in store.yarn(l.yarnID).map { "\($0.title.isEmpty ? "실" : $0.title) \(amountString(l.amount))\($0.unit)" } }
                toast.show(used.isEmpty ? "완성을 축하해요! 홈의 ‘완성작’에 모아 둘게요" : "완성을 축하해요! 보관함에서 \(used.joined(separator: ", "))를 뺐어요")
            } else if !hadDeducted.isEmpty {
                toast.show("진행 중으로 돌렸어요. 뺐던 실을 보관함에 다시 채웠어요")
            }
        } label: {
            Label(p.isDone ? "진행 중으로 되돌리기" : "완성으로 표시",
                  systemImage: p.isDone ? "arrow.uturn.backward" : "checkmark")
                .font(.app(.headline))
                .frame(maxWidth: .infinity)
                .padding(15)
                .foregroundStyle(Theme.sage)
                .background(p.isDone ? Theme.sageSoft : Color.clear, in: shape)
                .overlay(shape.strokeBorder(p.isDone ? Color.clear : Theme.sage, lineWidth: 1.5))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
    }

    // MARK: 동작

    private func changeRow(_ delta: Int) {
        var result: Store.RowResult?
        withAnimation(.snappy(duration: 0.2)) {
            result = store.changeRow(projectID, by: delta)
        }
        guard let result else { return }
        if result.isHit { Haptics.alert() } else { Haptics.tap() }
        if let m = result.message { toast.show(m) }
    }

    private func changeCounter(_ c: SubCounter, by delta: Int) {
        let r = store.changeCounter(projectID, counterID: c.id, by: delta)
        guard r.changed else { return }
        Haptics.light()
        if let m = r.message { toast.show(m) }
    }

    private func moveStep(_ c: SubCounter, by delta: Int, wholeRound: Bool) {
        var r = Store.StepResult()
        withAnimation(.snappy(duration: 0.2)) {
            r = store.moveStep(projectID, counterID: c.id, by: delta, wholeRound: wholeRound)
        }
        guard r.changed else { return }
        if r.allDone { Haptics.success() } else if r.roundDone { Haptics.alert() } else { Haptics.light() }
        if let m = r.message { toast.show(m) }
    }

    private func saveToLibrary() {
        if let sp = store.savePatternFromProject(projectID) {
            Haptics.success()
            toast.show("‘\(sp.name)’을 도안함에 저장했어요. 다음엔 홈의 도안함에서 바로 시작할 수 있어요")
        }
    }

    private func moveGuide(_ delta: Int) { moveGuide(delta, wholeRow: false) }

    private func moveGuide(_ delta: Int, wholeRow: Bool) {
        var r = Store.GuideResult()
        withAnimation(.snappy(duration: 0.2)) { r = store.moveGuide(projectID, by: delta, wholeRow: wholeRow) }
        guard r.changed else { return }
        if r.reachedTarget { Haptics.success() } else if r.rowDone { Haptics.alert() } else { Haptics.light() }
        if let m = r.message { toast.show(m) }
    }

    /// 도안 PDF에서 단 번호를 읽어요. auto면 못 찾았을 때 조용히 도안을 열어요
    private func readGuide(auto: Bool) {
        guard !readingGuide, let name = store.project(projectID)?.pattern?.fileName else {
            if auto { showPattern = true }
            return
        }
        readingGuide = true
        Task {
            let result = await GuideReader.read(pdfURL: Store.patternFileURL(name))
            readingGuide = false
            if result.isEmpty {
                if auto { showPattern = true } else { toast.show("도안에서 ‘1단:’ 같은 단 번호를 찾지 못했어요") }
            } else {
                guideDraft = GuideDraft(result: result, editing: false)
            }
        }
    }

    private func guideButtons(_ p: Project) -> some View {
        HStack(spacing: 8) {
            if p.pattern?.kind == .pdf {
                Button { readGuide(auto: false) } label: {
                    HStack(spacing: 8) {
                        if readingGuide { ProgressView().controlSize(.small) } else { Image(systemName: "doc.text.viewfinder") }
                        Text(readingGuide ? "도안 읽는 중…" : "도안에서 단 읽기")
                    }
                }
                .disabled(readingGuide)
            }
            Button { guideDraft = GuideDraft(result: GuideParser.Result(), editing: true, manual: true) } label: {
                Label(p.pattern?.kind == .pdf ? "직접 입력" : "단별 안내 직접 입력", systemImage: "square.and.pencil")
            }
        }
        .buttonStyle(ChipStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func afterEdit() {
        if let p = store.project(projectID) {
            notes = p.notes
        } else {
            dismiss() // 작품을 삭제했으면 목록으로
        }
    }
}

struct GuideDraft: Identifiable {
    let id = UUID()
    let result: GuideParser.Result
    let editing: Bool
    var manual = false
}

// MARK: - 행

struct ReminderRow: View {
    let reminder: Reminder
    let row: Int

    var body: some View {
        let idx = reminder.index(at: row)
        let next = reminder.next(after: row)
        let isHit = idx != nil

        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.label).font(.app(.body))
                Text(reminder.ruleText).font(.app(.caption)).opacity(0.75)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                if let idx {
                    Text("이번 단")
                    if reminder.times > 0 {
                        Text("\(idx + 1)/\(reminder.times)회").font(.app(.caption))
                    }
                } else if let next {
                    Text("\(next.row)단").monospacedDigit()
                    Text("\(next.row - row)단 후").font(.app(.caption)).foregroundStyle(Theme.muted)
                } else {
                    Text("완료").foregroundStyle(Theme.muted)
                }
            }
        }
        .foregroundStyle(isHit ? Theme.warnInk : Theme.text)
        .card(fill: isHit ? Theme.warnBg : Theme.surface, stroke: isHit ? Theme.warnLine : Theme.line)
        .accessibilityElement(children: .combine)
    }
}

struct CounterRow: View {
    let counter: SubCounter
    let row: Int
    let onChange: (Int) -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(counter.name).font(.app(.body))
                    if counter.linked {
                        Label("단 연동", systemImage: "link")
                            .font(.app(.caption2))
                            .foregroundStyle(Theme.sage)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.sageSoft, in: Capsule())
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(counter.displayValue(row: row))")
                        .font(.app(size: 28, relativeTo: .title2))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    if counter.max > 0 {
                        Text("/ \(counter.max)").foregroundStyle(Theme.muted)
                    }
                }
            }
            .foregroundStyle(Theme.text)

            Spacer(minLength: 4)

            if !counter.linked {
                roundButton("minus", label: "\(counter.name) 1 빼기", bg: Theme.surface2, fg: Theme.text) { onChange(-1) }
                roundButton("plus", label: "\(counter.name) 1 더하기", bg: Theme.accentSoft, fg: Theme.accentText) { onChange(1) }
            }
            Button(action: onEdit) {
                Image(systemName: "ellipsis")
                    .frame(width: 38, height: 38)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(Theme.muted)
            .accessibilityLabel("\(counter.name) 설정")
        }
        .padding(.vertical, -4)
        .card()
    }

    private func roundButton(_ symbol: String, label: String, bg: Color, fg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(PressStyle(bg: bg, fg: fg, radius: 24))
        .accessibilityLabel(label)
    }
}


// MARK: - 순서 카운터

/// "짧은뜨기 1 → 한길긴뜨기 1 → 사슬뜨기 2 → 한길긴뜨기 1"을 N번 반복할 때 지금 위치를 보여 줘요
struct SequenceCounterCard: View {
    let counter: SubCounter
    let onMove: (_ delta: Int, _ wholeRound: Bool) -> Void
    let onEdit: () -> Void

    private var steps: [String] { counter.steps }
    private var current: Int { min(counter.step, steps.count - 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(counter.name).font(.app(.body))
                Spacer(minLength: 4)
                Button { onMove(1, true) } label: { roundText }
                    .buttonStyle(.plain)
                    .disabled(counter.isFinished)
                    .accessibilityHint("남은 단계를 건너뛰고 이번 반복을 끝내요")
                Button(action: onEdit) {
                    Image(systemName: "ellipsis").frame(width: 32, height: 28).contentShape(Rectangle())
                }
                .foregroundStyle(Theme.muted)
                .accessibilityLabel("\(counter.name) 설정")
            }

            if counter.isFinished {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(counter.max)번 반복 완료", systemImage: "checkmark.circle.fill")
                        .font(.app(size: 22, relativeTo: .title3))
                        .foregroundStyle(Theme.sage)
                    Text("다음을 누르면 처음부터 다시 세요").font(.app(.caption)).foregroundStyle(Theme.muted)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("지금").font(.app(.caption)).foregroundStyle(Theme.muted).frame(width: 30, alignment: .leading)
                        Text(steps[current])
                            .font(.app(size: 24, relativeTo: .title2))
                            .contentTransition(.opacity)
                            .id(current)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("다음").font(.app(.caption)).foregroundStyle(Theme.muted).frame(width: 30, alignment: .leading)
                        Text(nextText).font(.app(.subheadline)).foregroundStyle(Theme.muted)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("지금 \(steps[current]), 단계 \(current + 1)/\(steps.count)")

                HStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { i in
                        Capsule()
                            .fill(i < current ? Theme.accentText.opacity(0.45) : i == current ? Theme.accentText : Theme.surface2)
                            .frame(height: 6)
                    }
                }
                .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                Button { onMove(-1, false) } label: {
                    Image(systemName: "arrow.uturn.backward").frame(width: 52, height: 52)
                }
                .buttonStyle(PressStyle(bg: Theme.surface2, fg: Theme.text, radius: 16))
                .disabled(counter.value == 0 && counter.step == 0)
                .accessibilityLabel("한 단계 뒤로")

                Button { onMove(1, false) } label: {
                    Label(counter.isFinished ? "처음부터" : "다음 단계", systemImage: counter.isFinished ? "arrow.counterclockwise" : "chevron.right")
                        .labelStyle(TrailingIconLabelStyle())
                        .font(.app(.headline))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(PressStyle(bg: Theme.accent, fg: Theme.accentInk, radius: 16))
            }
        }
        .foregroundStyle(Theme.text)
        .card()
    }

    private var roundText: some View {
        let now = counter.isFinished ? counter.max : counter.value + 1
        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(now)").font(.app(size: 22, relativeTo: .title3)).monospacedDigit().contentTransition(.numericText())
            Text(counter.max > 0 ? "/ \(counter.max)번째" : "번째").font(.app(.caption)).foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Theme.accentSoft, in: Capsule())
        .foregroundStyle(Theme.accentText)
    }

    private var nextText: String {
        if current + 1 < steps.count { return steps[current + 1] }
        let next = counter.value + 2
        if counter.max > 0 && next > counter.max { return counter.rowOnFinish ? "반복 끝 · 다음 단으로" : "반복 끝" }
        return "\(steps[0]) (\(next)번째)"
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) { configuration.title; configuration.icon }
    }
}
