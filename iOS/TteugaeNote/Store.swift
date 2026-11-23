import Foundation
import Observation

/// 모든 작품을 들고 있고, 바뀔 때마다 Documents/projects.json 에 저장해요.
/// (Documents 폴더는 아이폰 iCloud 백업에 포함돼요)
@Observable
final class Store {
    private(set) var projects: [Project] = []
    private(set) var stash = Stash()
    private(set) var patterns: [SavedPattern] = []
    private var undoStacks: [String: [Snapshot]] = [:]
    private let fileURL: URL

    struct Snapshot {
        let row: Int
        let counters: [SubCounter]
        let logKey: String
        let logValue: Int
        var guideStep = 0
        var guideStepRow = 0
    }

    struct RowResult {
        var message: String?
        var isHit: Bool
        var reachedTarget = false
    }

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("projects.json")
        if let data = try? Data(contentsOf: self.fileURL), let file = try? JSONDecoder().decode(BackupFile.self, from: data) {
            projects = file.projects
            stash = file.stash ?? Stash()
            patterns = file.patterns ?? []
        }
    }

    // MARK: 저장 / 백업

    static func decodeBackup(_ data: Data) throws -> [Project] {
        try JSONDecoder().decode(BackupFile.self, from: data).projects
    }

    func exportData() -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? enc.encode(BackupFile(projects: projects, stash: stash, patterns: patterns))) ?? Data()
    }

    private func save() {
        do {
            try exportData().write(to: fileURL, options: .atomic)
        } catch {
            print("저장 실패: \(error)")
        }
    }

    static func decodeStash(_ data: Data) -> Stash? {
        (try? JSONDecoder().decode(BackupFile.self, from: data))?.stash
    }

    func merge(_ incoming: [Project], stash incomingStash: Stash? = nil) {
        for p in incoming {
            if let i = index(p.id) { projects[i] = p } else { projects.append(p) }
        }
        if let s = incomingStash {
            for y in s.yarns {
                if let i = stash.yarns.firstIndex(where: { $0.id == y.id }) { stash.yarns[i] = y } else { stash.yarns.append(y) }
            }
            for n in s.needles {
                if let i = stash.needles.firstIndex(where: { $0.id == n.id }) { stash.needles[i] = n } else { stash.needles.append(n) }
            }
        }
        save()
    }

    // MARK: 실·바늘 보관함

    func saveYarn(_ yarn: StashYarn) {
        var y = yarn
        y.name = y.name.trimmingCharacters(in: .whitespacesAndNewlines)
        y.color = y.color.trimmingCharacters(in: .whitespacesAndNewlines)
        y.weight = y.weight.trimmingCharacters(in: .whitespacesAndNewlines)
        y.amount = max(0, y.amount)
        y.needleSize = String(y.needleSize.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s*(mm|호)$"#, with: "", options: .regularExpression).prefix(12))
        if !["mm", "호"].contains(y.needleUnit) { y.needleUnit = "mm" }
        if let i = stash.yarns.firstIndex(where: { $0.id == y.id }) {
            let old = stash.yarns[i].photo
            if !old.isEmpty && old != y.photo { Store.removePhotoFile(old) }
            stash.yarns[i] = y
        } else { stash.yarns.append(y) }
        save()
    }

    func deleteYarn(_ yarnID: String) {
        if let photo = yarn(yarnID)?.photo, !photo.isEmpty { Store.removePhotoFile(photo) }
        stash.yarns.removeAll { $0.id == yarnID }
        for i in projects.indices {
            projects[i].yarnLinks.removeAll { $0.yarnID == yarnID }
            projects[i].deducted.removeAll { $0.yarnID == yarnID }
        }
        save()
    }

    func saveNeedle(_ needle: StashNeedle) {
        var n = needle
        n.size = n.size.trimmingCharacters(in: .whitespacesAndNewlines)
        if let i = stash.needles.firstIndex(where: { $0.id == n.id }) { stash.needles[i] = n } else { stash.needles.append(n) }
        save()
    }

    func deleteNeedle(_ needleID: String) {
        stash.needles.removeAll { $0.id == needleID }
        for i in projects.indices { projects[i].needleIDs.removeAll { $0 == needleID } }
        save()
    }

    /// 작품들에 연결한 양의 합
    /// 완성한 작품의 실은 이미 가진 양에서 빠졌으니 세지 않아요
    func reserved(_ yarnID: String) -> Double {
        projects.filter { !$0.isDone }.reduce(0) { sum, p in sum + p.yarnLinks.filter { $0.yarnID == yarnID }.reduce(0) { $0 + $1.amount } }
    }

    /// 남은 양 = 가진 양 − 작품들에 연결한 양
    func remaining(_ yarn: StashYarn) -> Double { yarn.amount - reserved(yarn.id) }

    func projectsUsing(yarnID: String) -> [Project] { projects.filter { !$0.isDone && $0.yarnLinks.contains { $0.yarnID == yarnID } } }
    func projectsDone(yarnID: String) -> [Project] { projects.filter { $0.isDone && $0.deducted.contains { $0.yarnID == yarnID } } }
    func projectsUsing(needleID: String) -> [Project] { projects.filter { $0.needleIDs.contains(needleID) } }

    func yarn(_ id: String) -> StashYarn? { stash.yarns.first { $0.id == id } }
    func needle(_ id: String) -> StashNeedle? { stash.needles.first { $0.id == id } }

    /// 작품에 실 연결 (이미 있으면 양만 바꿔요, 0이면 연결 해제)
    func linkYarn(_ id: String, yarnID: String, amount: Double) {
        mutate(id) { q in
            q.yarnLinks.removeAll { $0.yarnID == yarnID }
            if amount > 0 { q.yarnLinks.append(YarnLink(yarnID: yarnID, amount: amount)) }
        }
        redeductIfDone(id, yarnID: yarnID)
    }

    func unlinkYarn(_ id: String, yarnID: String) {
        mutate(id) { q in q.yarnLinks.removeAll { $0.yarnID == yarnID } }
        redeductIfDone(id, yarnID: yarnID)
    }

    /// 완성한 작품의 실 양을 바꾸면 보관함에서 뺀 양도 맞춰요
    private func redeductIfDone(_ id: String, yarnID: String) {
        guard let p = project(id), p.isDone else { return }
        restoreDeducted(p.deducted.filter { $0.yarnID == yarnID })
        let taken = deduct(p.yarnLinks.filter { $0.yarnID == yarnID })
        mutate(id) { q in
            q.deducted.removeAll { $0.yarnID == yarnID }
            q.deducted += taken
        }
    }

    func toggleNeedle(_ id: String, needleID: String) {
        mutate(id) { q in
            if q.needleIDs.contains(needleID) { q.needleIDs.removeAll { $0 == needleID } } else { q.needleIDs.append(needleID) }
        }
    }

    // MARK: 도우미

    static var nowMs: Double { Date().timeIntervalSince1970 * 1000 }

    static func todayKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func project(_ id: String) -> Project? { projects.first { $0.id == id } }
    private func index(_ id: String) -> Int? { projects.firstIndex { $0.id == id } }

    private func mutate(_ id: String, _ body: (inout Project) -> Void) {
        guard let i = index(id) else { return }
        body(&projects[i])
        projects[i].updatedAt = Store.nowMs
        save()
    }

    func rowsToday() -> Int {
        let k = Store.todayKey()
        return projects.reduce(0) { $0 + ($1.log[k] ?? 0) }
    }

    // MARK: 단

    func changeRow(_ id: String, by delta: Int) -> RowResult? {
        guard let p = project(id) else { return nil }
        let next = max(0, p.row + delta)
        guard next != p.row else { return nil }
        pushUndo(p)
        mutate(id) { q in
            q.row = next
            let k = Store.todayKey()
            let v = max(0, (q.log[k] ?? 0) + delta)
            q.log[k] = v > 0 ? v : nil
        }
        guard delta > 0, let updated = project(id) else { return RowResult(message: nil, isHit: false) }

        var messages: [String] = []
        let hits = updated.hits(at: next)
        if !hits.isEmpty {
            messages.append("\(next)단: " + hits.map { $0.reminder.label }.joined(separator: ", "))
        }
        if updated.targetRows > 0 && next == updated.targetRows {
            messages.append("목표 \(updated.targetRows)단에 도착했어요!")
        }
        return RowResult(message: messages.isEmpty ? nil : messages.joined(separator: "\n"),
                         isHit: !messages.isEmpty,
                         reachedTarget: updated.targetRows > 0 && next == updated.targetRows)
    }

    func setRow(_ id: String, _ n: Int) {
        guard let p = project(id) else { return }
        let v = min(99_999, max(0, n))
        guard v != p.row else { return }
        pushUndo(p)
        mutate(id) { $0.row = v }
    }

    // MARK: 되돌리기

    private func pushUndo(_ p: Project) {
        let k = Store.todayKey()
        var stack = undoStacks[p.id] ?? []
        stack.append(Snapshot(row: p.row, counters: p.counters, logKey: k, logValue: p.log[k] ?? 0,
                              guideStep: p.guideStep, guideStepRow: p.guideStepRow))
        if stack.count > 200 { stack.removeFirst() }
        undoStacks[p.id] = stack
    }

    func canUndo(_ id: String) -> Bool { !(undoStacks[id] ?? []).isEmpty }

    @discardableResult
    func undo(_ id: String) -> Bool {
        guard var stack = undoStacks[id], let snap = stack.popLast() else { return false }
        undoStacks[id] = stack
        mutate(id) { q in
            q.row = snap.row
            for old in snap.counters {
                if let j = q.counters.firstIndex(where: { $0.id == old.id }) {
                    q.counters[j].value = old.value
                    q.counters[j].offset = old.offset
                }
            }
            q.log[snap.logKey] = snap.logValue > 0 ? snap.logValue : nil
            q.guideStep = snap.guideStep
            q.guideStepRow = snap.guideStepRow
        }
        return true
    }

    // MARK: 도안 단별 안내

    // MARK: 도안함

    static func cleanGuide(_ rows: [GuideRow]) -> [GuideRow] {
        rows.map { r -> GuideRow in
            var r = r
            r.text = GuideParser.tidy(r.text)
            r.from = min(9_999, max(1, r.from)); r.to = min(9_999, max(r.from, r.to))
            return r
        }.filter { !$0.text.isEmpty }.sorted { $0.from < $1.from }
    }

    /// 도안 파일을 새 이름으로 복사해요 (작품과 도안함이 서로의 파일을 지우지 않게)
    static func copyPatternFile(_ ref: PatternRef?) -> PatternRef? {
        guard var r = ref else { return nil }
        r.page = 0
        r.markerY = nil
        guard r.kind == .pdf, let name = r.fileName else { return r }
        let newName = "\(UUID().uuidString).pdf"
        do { try FileManager.default.copyItem(at: patternFileURL(name), to: patternFileURL(newName)) } catch { return nil }
        r.fileName = newName
        return r
    }

    static func removePatternRefFile(_ ref: PatternRef?) {
        guard let name = ref?.fileName else { return }
        try? FileManager.default.removeItem(at: patternFileURL(name))
        try? FileManager.default.removeItem(at: patternsDir.appendingPathComponent(name + ".ink", isDirectory: true))
    }

    static func storePatternData(_ data: Data, title: String) throws -> PatternRef {
        let name = "\(UUID().uuidString).pdf"
        try data.write(to: patternFileURL(name), options: .atomic)
        return PatternRef(kind: .pdf, title: title, fileName: name, url: nil)
    }

    func savePattern(_ sp: SavedPattern) {
        var p = sp
        p.name = String(p.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        if p.name.isEmpty { p.name = p.file?.title ?? "도안" }
        p.yarn = p.yarn.trimmingCharacters(in: .whitespacesAndNewlines)
        p.needle = p.needle.trimmingCharacters(in: .whitespacesAndNewlines)
        p.guide = Store.cleanGuide(p.guide)
        p.targetRows = max(0, min(99_999, p.targetRows))
        if let i = patterns.firstIndex(where: { $0.id == p.id }) {
            if patterns[i].file?.fileName != p.file?.fileName { Store.removePatternRefFile(patterns[i].file) }
            patterns[i] = p
        } else {
            patterns.insert(p, at: 0)
        }
        save()
    }

    func deletePattern(_ patternID: String) {
        guard let p = patterns.first(where: { $0.id == patternID }) else { return }
        Store.removePatternRefFile(p.file)
        patterns.removeAll { $0.id == patternID }
        save()
    }

    /// 작품의 도안·안내·재료를 도안함에 저장해요
    @discardableResult
    func savePatternFromProject(_ id: String) -> SavedPattern? {
        guard let q = project(id) else { return nil }
        let sp = SavedPattern(name: q.name, file: Store.copyPatternFile(q.pattern), guide: q.guide, guidePart: q.guidePart,
                              yarn: q.yarn, needle: q.needle, targetRows: q.targetRows)
        savePattern(sp)
        return patterns.first { $0.id == sp.id }
    }

    /// 도안함의 도안으로 새 작품을 시작해요. 새 작품 id를 돌려줘요
    func startProject(from patternID: String) -> String? {
        guard let sp = patterns.first(where: { $0.id == patternID }) else { return nil }
        var p = Project(name: sp.name)
        p.yarn = sp.yarn
        p.needle = sp.needle
        p.targetRows = sp.targetRows > 0 ? sp.targetRows : sp.guideMaxRow
        p.notes = sp.notes
        p.pattern = Store.copyPatternFile(sp.file)
        p.guide = sp.guide.map { var g = $0; g.id = UUID().uuidString; return g }
        p.guidePart = sp.guidePart
        return saveProject(p)
    }

    func setGuide(_ id: String, rows: [GuideRow], part: String,
                  targetRows: Int? = nil, yarn: String? = nil, needle: String? = nil, extraNote: String? = nil) {
        let clean = rows.map { r -> GuideRow in
            var r = r
            r.text = GuideParser.tidy(r.text)
            r.from = min(9_999, max(1, r.from)); r.to = min(9_999, max(r.from, r.to))
            return r
        }.filter { !$0.text.isEmpty }.sorted { $0.from < $1.from }
        mutate(id) { q in
            q.guide = clean
            q.guidePart = clean.isEmpty ? "" : String(part.prefix(30))
            q.guideStep = 0
            q.guideStepRow = 0
            if let targetRows, targetRows > 0 { q.targetRows = min(99_999, targetRows) }
            if let yarn, !yarn.isEmpty, q.yarn.isEmpty { q.yarn = yarn }
            if let needle, !needle.isEmpty, q.needle.isEmpty { q.needle = needle }
            if let extraNote, !extraNote.isEmpty, !q.notes.contains(extraNote) {
                q.notes = q.notes.isEmpty ? extraNote : q.notes + "\n\n" + extraNote
            }
        }
    }

    struct GuideResult {
        var changed = false
        var rowDone = false
        var message: String?
        var reachedTarget = false
    }

    /// 안내 단계 넘기기. 마지막 단계에서 다음을 누르면 다음 단으로 넘어가요
    func moveGuide(_ id: String, by delta: Int, wholeRow: Bool = false) -> GuideResult {
        guard let p = project(id), let g = p.guideRow(at: p.guideRowNumber) else { return GuideResult() }
        let r = p.guideRowNumber
        let count = max(1, g.steps.count)
        let s = p.currentGuideStep
        if delta < 0 {
            guard s > 0 else { return GuideResult() }
            pushUndo(p)
            mutate(id) { $0.guideStep = s - 1; $0.guideStepRow = r }
            return GuideResult(changed: true)
        }
        if !wholeRow && s + 1 < count {
            pushUndo(p)
            mutate(id) { $0.guideStep = s + 1; $0.guideStepRow = r }
            return GuideResult(changed: true)
        }
        // 이 단 끝
        let next = r + 1
        pushUndo(p)
        mutate(id) { q in
            q.row = next
            q.guideStep = 0
            q.guideStepRow = next
            let k = Store.todayKey()
            q.log[k] = (q.log[k] ?? 0) + 1
        }
        var res = GuideResult(changed: true, rowDone: true)
        var messages = ["\(r)단 끝! \(next)단으로 넘어가요"]
        if let u = project(id) {
            let hits = u.hits(at: next)
            if !hits.isEmpty { messages.append("\(next)단: " + hits.map { $0.reminder.label }.joined(separator: ", ")) }
            if u.targetRows > 0 && next == u.targetRows {
                messages.append("목표 \(u.targetRows)단에 도착했어요!")
                res.reachedTarget = true
            } else if u.guideMaxRow > 0 && r == u.guideMaxRow {
                messages = ["도안의 마지막 \(r)단까지 끝냈어요!"]
                res.reachedTarget = true
            }
        }
        res.message = messages.joined(separator: "\n")
        return res
    }

    // MARK: 보조 카운터

    /// 값이 바뀌었으면 true와 (있으면) 알릴 메시지를 돌려줘요
    func changeCounter(_ id: String, counterID: String, by delta: Int) -> (changed: Bool, message: String?) {
        guard let p = project(id),
              let c = p.counters.first(where: { $0.id == counterID }),
              !c.linked else { return (false, nil) }
        var v = c.value + delta
        var message: String?
        if c.max > 0 && v > c.max {
            v = 1
            message = "\(c.name) \(c.max)회 한 바퀴 완료"
        }
        v = max(0, v)
        guard v != c.value else { return (false, nil) }
        pushUndo(p)
        mutate(id) { q in
            if let j = q.counters.firstIndex(where: { $0.id == counterID }) { q.counters[j].value = v }
        }
        return (true, message)
    }

    struct StepResult {
        var changed = false
        var message: String?
        var roundDone = false   // 한 번 반복을 끝냄
        var allDone = false     // 정한 횟수를 다 끝냄
    }

    /// 순서 카운터: delta 1이면 다음 단계, -1이면 이전 단계. wholeRound면 남은 단계를 건너뛰고 반복 하나를 끝내요
    func moveStep(_ id: String, counterID: String, by delta: Int, wholeRound: Bool = false) -> StepResult {
        guard let p = project(id), let c = p.counters.first(where: { $0.id == counterID }), c.isSequence else { return StepResult() }
        var n = c
        var r = StepResult(changed: true)
        var rowDelta = 0
        if delta < 0 {
            if n.step > 0 { n.step -= 1 }
            else if n.value > 0 { n.value -= 1; n.step = n.steps.count - 1 }
            else { return StepResult() }
        } else if n.isFinished {
            n.value = 0; n.step = 0
            r.message = "\(n.name) 처음부터 다시 세요"
        } else {
            n.step = wholeRound ? n.steps.count : n.step + 1
            if n.step >= n.steps.count {
                n.step = 0
                n.value += 1
                r.roundDone = true
                if n.max > 0 && n.value >= n.max {
                    r.allDone = true
                    if n.rowOnFinish {
                        n.value = 0
                        rowDelta = 1
                        r.message = "\(n.name) \(n.max)번 끝! \(p.row + 1)단으로 넘어가요"
                    } else {
                        r.message = "\(n.name) \(n.max)번 반복 완료!"
                    }
                } else {
                    r.message = n.max > 0 ? "\(n.value)번째 끝 · \(n.value + 1)/\(n.max)번째 시작" : "\(n.value)번째 끝"
                }
            }
        }
        pushUndo(p)
        mutate(id) { q in
            if let j = q.counters.firstIndex(where: { $0.id == counterID }) { q.counters[j] = n }
            if rowDelta > 0 {
                q.row += rowDelta
                let k = Store.todayKey()
                q.log[k] = (q.log[k] ?? 0) + rowDelta
            }
        }
        if rowDelta > 0, let updated = project(id) {
            let hits = updated.hits(at: updated.row)
            if !hits.isEmpty { r.message = (r.message ?? "") + "\n\(updated.row)단: " + hits.map { $0.reminder.label }.joined(separator: ", ") }
        }
        return r
    }

    func saveCounter(_ id: String, counterID: String?, name: String, max maxValue: Int, linked: Bool,
                     steps rawSteps: [String] = [], rowOnFinish: Bool = false) {
        let steps = rawSteps.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40)) }.filter { !$0.isEmpty }
        let linked = steps.isEmpty ? linked : false
        mutate(id) { q in
            if let counterID, let j = q.counters.firstIndex(where: { $0.id == counterID }) {
                var c = q.counters[j]
                let current = c.displayValue(row: q.row)
                if linked && !c.linked { c.offset = Swift.max(0, q.row - current) } // 지금 값에서 이어서 셈
                if !linked && c.linked { c.value = current }
                c.name = name
                c.max = maxValue
                c.linked = linked
                if c.steps != steps { c.step = 0 }
                c.steps = steps
                c.rowOnFinish = !steps.isEmpty && rowOnFinish
                if !c.linked && c.max > 0 && c.value > c.max { c.value = c.max }
                q.counters[j] = c
            } else {
                q.counters.append(SubCounter(name: name, max: maxValue, linked: linked, offset: q.row,
                                             steps: steps, rowOnFinish: !steps.isEmpty && rowOnFinish))
            }
        }
    }

    func resetCounter(_ id: String, counterID: String) {
        guard let p = project(id) else { return }
        pushUndo(p)
        mutate(id) { q in
            guard let j = q.counters.firstIndex(where: { $0.id == counterID }) else { return }
            if q.counters[j].linked { q.counters[j].offset = q.row } else { q.counters[j].value = 0; q.counters[j].step = 0 }
        }
    }

    func deleteCounter(_ id: String, counterID: String) {
        mutate(id) { q in q.counters.removeAll { c in c.id == counterID } }
    }

    // MARK: 작품

    @discardableResult
    func saveProject(_ draft: Project) -> String {
        var p = draft
        p.name = String(p.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        p.yarn = p.yarn.trimmingCharacters(in: .whitespacesAndNewlines)
        p.needle = p.needle.trimmingCharacters(in: .whitespacesAndNewlines)
        p.targetRows = max(0, p.targetRows)
        p.castOn = max(0, p.castOn)
        p.reminders = p.reminders.compactMap { $0.normalized() }
        p.updatedAt = Store.nowMs
        if let i = index(p.id) { projects[i] = p } else { projects.append(p) }
        save()
        return p.id
    }

    /// 완성하면 연결한 실을 보관함에서 빼고, 되돌리면 다시 채워요. 뺀 실 목록을 돌려줘요.
    @discardableResult
    func setDone(_ id: String, _ done: Bool) -> [YarnLink] {
        guard let p = project(id) else { return [] }
        restoreDeducted(p.deducted)
        var taken: [YarnLink] = []
        if done { taken = deduct(p.yarnLinks) }
        mutate(id) { q in
            q.isDone = done
            q.pausedAt = nil
            q.doneAt = done ? Store.nowMs : nil
            q.deducted = taken
        }
        return taken
    }

    /// 보관함에서 실을 빼요 (가진 양보다 많이는 못 빼요). 실제로 뺀 양을 돌려줘요.
    private func deduct(_ links: [YarnLink]) -> [YarnLink] {
        links.compactMap { l in
            guard let i = stash.yarns.firstIndex(where: { $0.id == l.yarnID }) else { return nil }
            let take = min(l.amount, stash.yarns[i].amount)
            guard take > 0 else { return nil }
            stash.yarns[i].amount -= take
            return YarnLink(yarnID: l.yarnID, amount: take)
        }
    }

    private func restoreDeducted(_ links: [YarnLink]) {
        for l in links {
            if let i = stash.yarns.firstIndex(where: { $0.id == l.yarnID }) { stash.yarns[i].amount += l.amount }
        }
    }

    // MARK: 잠시 멈춤 / 변경 기록

    func pause(_ id: String, note: String) {
        mutate(id) { q in
            q.status = "paused"
            q.pausedAt = Store.nowMs
            q.resumeNote = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
        }
    }

    func resume(_ id: String) {
        mutate(id) { q in
            q.status = "active"
            q.pausedAt = nil
        }
    }

    func addChange(_ id: String, text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        mutate(id) { q in q.changes.insert(ChangeNote(row: q.row, text: String(t.prefix(300))), at: 0) }
    }

    /// 제작 기록 저장 (빈 실 줄은 빼요)
    func saveRecord(_ id: String, gauge: Gauge, yarns: [YarnUse], sizeNote: String) {
        mutate(id) { q in
            var g = gauge
            g.needle = g.needle.trimmingCharacters(in: .whitespacesAndNewlines)
            g.stitches = max(0, g.stitches)
            g.rows = max(0, g.rows)
            q.gauge = g
            q.yarnsUsed = yarns.map { y in
                var y = y
                y.name = y.name.trimmingCharacters(in: .whitespacesAndNewlines)
                y.color = y.color.trimmingCharacters(in: .whitespacesAndNewlines)
                y.amount = max(0, y.amount)
                return y
            }.filter { !$0.name.isEmpty || !$0.color.isEmpty || $0.amount > 0 }
            q.sizeNote = sizeNote.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func deleteChange(_ id: String, changeID: String) {
        mutate(id) { q in q.changes.removeAll { c in c.id == changeID } }
    }

    func setNotes(_ id: String, _ notes: String) {
        guard let p = project(id), p.notes != notes else { return }
        mutate(id) { $0.notes = notes }
    }

    func deleteProject(_ id: String) {
        removePatternFile(project(id)?.pattern)
        project(id)?.photos.forEach { try? FileManager.default.removeItem(at: Store.photoURL($0.fileName)) }
        projects.removeAll { $0.id == id }
        undoStacks[id] = nil
        save()
    }

    // MARK: 사진

    static var photosDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func photoURL(_ fileName: String) -> URL { photosDir.appendingPathComponent(fileName) }

    /// 사진 파일만 저장하고 이름을 돌려줘요 (실 사진 등)
    static func savePhotoFile(_ jpegData: Data) throws -> String {
        let name = "\(UUID().uuidString).jpg"
        try jpegData.write(to: photoURL(name), options: .atomic)
        return name
    }

    static func removePhotoFile(_ fileName: String) {
        guard !fileName.isEmpty else { return }
        try? FileManager.default.removeItem(at: photoURL(fileName))
    }

    /// JPEG 데이터를 파일로 저장하고 작품에 붙여요 (지금 단도 함께 기록)
    @discardableResult
    func addPhoto(_ id: String, jpegData: Data) throws -> ProjectPhoto? {
        guard let p = project(id) else { return nil }
        let photo = ProjectPhoto(fileName: "\(UUID().uuidString).jpg", row: p.row)
        try jpegData.write(to: Store.photoURL(photo.fileName), options: .atomic)
        mutate(id) { $0.photos.append(photo) }
        return photo
    }

    func setPhotoCaption(_ id: String, photoID: String, _ caption: String) {
        let t = String(caption.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
        guard let p = project(id), let ph = p.photos.first(where: { $0.id == photoID }), ph.caption != t else { return }
        mutate(id) { q in
            if let i = q.photos.firstIndex(where: { $0.id == photoID }) { q.photos[i].caption = t }
        }
    }

    func deletePhoto(_ id: String, photoID: String) {
        guard let ph = project(id)?.photos.first(where: { $0.id == photoID }) else { return }
        try? FileManager.default.removeItem(at: Store.photoURL(ph.fileName))
        mutate(id) { $0.photos.removeAll { $0.id == photoID } }
    }

    // MARK: 도안

    static var patternsDir: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Patterns", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func patternFileURL(_ fileName: String) -> URL { patternsDir.appendingPathComponent(fileName) }

    /// 파일 앱에서 고른 PDF를 앱 안으로 복사해서 작품에 붙여요
    func importPDF(_ id: String, from source: URL) throws {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        let name = "\(UUID().uuidString).pdf"
        try FileManager.default.copyItem(at: source, to: Store.patternFileURL(name))
        let title = source.deletingPathExtension().lastPathComponent
        setPattern(id, PatternRef(kind: .pdf, title: title.isEmpty ? "PDF 도안" : title, fileName: name, url: nil))
    }

    /// 웹 도안 주소를 붙여요. 주소가 이상하면 false
    @discardableResult
    func setWebPattern(_ id: String, _ text: String) -> Bool {
        guard let url = Store.normalizedWebURL(text) else { return false }
        let title = (url.host ?? "웹 도안").replacingOccurrences(of: "www.", with: "")
        setPattern(id, PatternRef(kind: .web, title: title, fileName: nil, url: url.absoluteString))
        return true
    }

    static func normalizedWebURL(_ text: String) -> URL? {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !t.contains(" ") else { return nil }
        let lower = t.lowercased()
        if lower.hasPrefix("http://") { t = "https://" + t.dropFirst(7) }      // 앱은 https만 열 수 있어요
        else if !lower.hasPrefix("https://") { t = "https://" + t }
        guard let url = URL(string: t), let host = url.host, host.contains(".") else { return nil }
        return url
    }

    func setPattern(_ id: String, _ ref: PatternRef?) {
        let old = project(id)?.pattern
        mutate(id) { $0.pattern = ref }
        if old?.fileName != ref?.fileName { removePatternFile(old) }
    }

    func setPatternPage(_ id: String, _ page: Int) {
        guard let p = project(id), p.pattern != nil, p.pattern?.page != page else { return }
        mutate(id) { $0.pattern?.page = page }
    }

    /// 이미지 등을 PDF로 바꾼 데이터를 도안으로 저장
    func importPDFData(_ id: String, data: Data, title: String) throws {
        let name = "\(UUID().uuidString).pdf"
        try data.write(to: Store.patternFileURL(name), options: .atomic)
        setPattern(id, PatternRef(kind: .pdf, title: title.isEmpty ? "도안" : title, fileName: name, url: nil))
    }

    /// 도안 쪽마다 손글씨(필기)를 저장하는 파일
    static func inkURL(_ fileName: String, page: Int) -> URL {
        let dir = patternsDir.appendingPathComponent(fileName + ".ink", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(page).drawing")
    }

    func setMarker(_ id: String, _ y: Double?) {
        guard let p = project(id), p.pattern != nil, p.pattern?.markerY != y else { return }
        mutate(id) { $0.pattern?.markerY = y }
    }

    private func removePatternFile(_ ref: PatternRef?) {
        guard let name = ref?.fileName else { return }
        try? FileManager.default.removeItem(at: Store.patternFileURL(name))
        try? FileManager.default.removeItem(at: Store.patternsDir.appendingPathComponent(name + ".ink", isDirectory: true))
    }
}
