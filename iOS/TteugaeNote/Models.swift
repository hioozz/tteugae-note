import Foundation

// 데이터 형식은 웹 버전(app.js)과 같아서, 웹 버전 백업 파일을 그대로 가져올 수 있어요.

/// "every 단마다, from 단부터, times 회(0이면 무제한)" 반복 알림
struct Reminder: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var label: String
    var every: Int
    var from: Int
    var times: Int
    var kind: String = "note"   // "inc" 늘림 · "dec" 줄임 · "note" 기타
    var stitches: Int = 0       // 늘림·줄임 한 번에 바뀌는 코 수

    var kindLabel: String? { kind == "inc" ? "늘림" : kind == "dec" ? "줄임" : nil }
    var stitchSign: Int { kind == "inc" ? 1 : kind == "dec" ? -1 : 0 }

    /// row 단까지 끝낸 횟수
    func doneCount(at row: Int) -> Int {
        guard every > 0, row >= from else { return 0 }
        let n = (row - from) / every + 1
        return times > 0 ? Swift.min(n, times) : n
    }

    /// 이 단이 알림 단이면 몇 번째(0부터)인지, 아니면 nil
    func index(at row: Int) -> Int? {
        guard every > 0, row >= from else { return nil }
        let d = row - from
        guard d % every == 0 else { return nil }
        let i = d / every
        if times > 0 && i >= times { return nil }
        return i
    }

    /// row 다음에 오는 알림 단
    func next(after row: Int) -> (row: Int, index: Int)? {
        guard every > 0 else { return nil }
        let n = row < from ? from : from + ((row - from) / every + 1) * every
        let i = (n - from) / every
        if times > 0 && i >= times { return nil }
        return (n, i)
    }

    var ruleText: String {
        var parts: [String] = []
        if let k = kindLabel { parts.append(stitches > 0 ? "\(k) \(stitches)코씩" : k) }
        parts.append("\(every)단마다")
        if from != every { parts.append("\(from)단부터") }
        if times > 0 { parts.append("총 \(times)회") }
        return parts.joined(separator: " · ")
    }

    func normalized() -> Reminder? {
        guard every >= 1 else { return nil }
        var r = self
        r.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !["inc", "dec", "note"].contains(r.kind) { r.kind = "note" }
        r.stitches = Swift.max(0, stitches)
        if r.kind != "note" && r.stitches == 0 { r.stitches = 2 }
        if r.kind == "note" { r.stitches = 0 }
        if r.label.isEmpty { r.label = r.kindLabel.map { "\($0) \(r.stitches)코" } ?? "\(every)단마다 할 일" }
        if r.from < 1 { r.from = every }
        r.times = Swift.max(0, times)
        return r
    }
}

/// 무늬 반복, 코 수 등을 따로 세는 카운터
struct SubCounter: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var value: Int = 0
    var max: Int = 0          // 0이면 최대값 없음
    var linked: Bool = false  // 단과 연동
    var offset: Int = 0       // 연동 카운터가 0이 되는 단
    var steps: [String] = []  // 순서 카운터: 한 번 반복할 때 뜨는 순서 (비어 있으면 일반 카운터)
    var step: Int = 0         // 순서 카운터: 지금 하는 단계 (0부터)
    var rowOnFinish = false   // 순서 카운터: 반복을 다 끝내면 단 +1

    var isSequence: Bool { !steps.isEmpty }
    /// 순서 카운터에서 반복을 다 끝냈는지
    var isFinished: Bool { isSequence && max > 0 && value >= max }

    /// 연동 카운터는 값을 저장하지 않고 현재 단에서 계산해요 (되돌리기가 항상 맞게 동작)
    func displayValue(row: Int) -> Int {
        guard linked else { return value }
        let n = row - offset
        if n <= 0 { return 0 }
        return max > 0 ? ((n - 1) % max) + 1 : n
    }
}

/// 작품에 붙인 도안 (PDF 파일 또는 웹 링크)
struct PatternRef: Codable, Hashable {
    enum Kind: String, Codable { case pdf, web }
    var kind: Kind
    var title: String
    var fileName: String?   // PDF: Documents/Patterns 안의 파일 이름
    var url: String?        // 웹 도안 주소
    var page: Int = 0       // PDF에서 마지막으로 보던 쪽 (0부터)
    var markerY: Double? = nil  // 줄 표시 막대 위치 (nil이면 꺼짐)
}

/// 도안에서 읽은 단별 안내 (from~to단에 같은 내용)
struct GuideRow: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var from: Int
    var to: Int
    var text: String
    var total: Int = 0          // 도안에 적힌 총 코 수 (0이면 없음)
    var label: String { from == to ? "\(from)단" : "\(from)~\(to)단" }
    var steps: [String] { GuideParser.steps(text) }
}

/// 작품 사진: 파일은 Documents/Photos 안에 있어요
struct ProjectPhoto: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var fileName: String
    var date: Double = Date().timeIntervalSince1970 * 1000
    var row: Int = 0          // 찍었을 때의 단
    var caption: String = ""
    var createdDate: Date { Date(timeIntervalSince1970: date / 1000) }
}

/// 게이지: 10cm 안의 코 수 × 단 수
struct Gauge: Codable, Hashable {
    var stitches: Int = 0
    var rows: Int = 0
    var needle: String = ""
    var isEmpty: Bool { stitches == 0 && rows == 0 && needle.isEmpty }
    var text: String {
        var s = "10cm에 \(stitches)코 × \(rows)단"
        if stitches == 0 { s = "10cm에 \(rows)단" } else if rows == 0 { s = "10cm에 \(stitches)코" }
        if stitches == 0 && rows == 0 { s = "" }
        return [s, needle].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// 실제로 쓴 실
struct YarnUse: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var color: String = ""
    var amount: Double = 0
    var unit: String = "볼"   // 볼 · g · m
    var amountText: String {
        guard amount > 0 else { return "" }
        let n = amount.rounded() == amount ? String(Int(amount)) : String(format: "%.1f", amount)
        return "\(n)\(unit == "볼" ? "볼" : unit)"
    }
    var text: String { [[name, color].filter { !$0.isEmpty }.joined(separator: " "), amountText].filter { !$0.isEmpty }.joined(separator: " · ") }
}

/// 도안과 다르게 바꾼 점 기록
struct ChangeNote: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var date: Double = Date().timeIntervalSince1970 * 1000
    var row: Int
    var text: String
    var dateValue: Date { Date(timeIntervalSince1970: date / 1000) }
}

struct ReminderHit: Identifiable {
    let reminder: Reminder
    let index: Int
    var id: String { reminder.id }
}

struct Project: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var yarn: String = ""
    var needle: String = ""
    var targetRows: Int = 0
    var castOn: Int = 0                    // 시작 코 수 (0이면 코 수 계산 안 함)
    var row: Int = 0
    var notes: String = ""
    var status: String = "active"
    var reminders: [Reminder] = []
    var counters: [SubCounter] = []
    var log: [String: Int] = [:]          // "yyyy-MM-dd": 그날 뜬 단수
    var pattern: PatternRef?              // 도안
    var pausedAt: Double?                 // 잠시 멈춘 시각
    var doneAt: Double?                   // 완성한 시각
    var resumeNote: String = ""           // 다시 시작할 때 볼 메모
    var changes: [ChangeNote] = []        // 변경 기록
    var gauge: Gauge = Gauge()            // 제작 기록: 게이지
    var yarnsUsed: [YarnUse] = []         // 제작 기록: 사용한 실
    var sizeNote: String = ""             // 제작 기록: 사이즈·수정 사항
    var yarnLinks: [YarnLink] = []        // 보관함 실 연결
    var needleIDs: [String] = []          // 보관함 바늘 연결
    var deducted: [YarnLink] = []         // 완성할 때 보관함에서 뺀 실 (되돌리면 다시 채워요)
    var photos: [ProjectPhoto] = []       // 뜨는 중·완성 사진 (오래된 것부터)
    var guide: [GuideRow] = []            // 도안에서 읽은 단별 안내
    var guidePart: String = ""            // 안내를 가져온 부분 이름 (예: 푸딩)
    var guideStep: Int = 0                // 안내 단계: guideStepRow단에서 몇 번째 단계인지
    var guideStepRow: Int = 0
    var createdAt: Double = Date().timeIntervalSince1970 * 1000
    var updatedAt: Double = Date().timeIntervalSince1970 * 1000

    var isDone: Bool {
        get { status == "done" }
        set { status = newValue ? "done" : "active" }
    }
    var isPaused: Bool { status == "paused" }
    var hasRecord: Bool { !gauge.isEmpty || !yarnsUsed.isEmpty || !sizeNote.isEmpty }
    var pausedDate: Date? { pausedAt.map { Date(timeIntervalSince1970: $0 / 1000) } }
    /// 완성한 날 (예전 데이터는 마지막 수정 시각으로)
    var doneDate: Date { Date(timeIntervalSince1970: (doneAt ?? updatedAt) / 1000) }
    var createdDate: Date { Date(timeIntervalSince1970: createdAt / 1000) }
    /// 시작부터 완성까지 걸린 날 (같은 날이면 1일)
    var daysTaken: Int {
        let cal = Calendar.current
        let d = cal.dateComponents([.day], from: cal.startOfDay(for: createdDate), to: cal.startOfDay(for: doneDate)).day ?? 0
        return max(1, d + 1)
    }
    var updatedDate: Date { Date(timeIntervalSince1970: updatedAt / 1000) }
    var meta: String { [yarn, needle].filter { !$0.isEmpty }.joined(separator: " · ") }
    var progress: Double? { targetRows > 0 ? min(1, Double(row) / Double(targetRows)) : nil }

    /// 늘림·줄임을 반영한 지금 코 수
    func stitchCount(at row: Int) -> Int? {
        guard castOn > 0 else { return nil }
        return castOn + reminders.reduce(0) { $0 + $1.stitchSign * $1.stitches * $1.doneCount(at: row) }
    }

    /// 지금 보여 줄 안내 단 (0단이면 1단부터)
    var guideRowNumber: Int { max(1, row) }
    func guideRow(at row: Int) -> GuideRow? { guide.first { $0.from <= row && row <= $0.to } }
    var guideMaxRow: Int { guide.map(\.to).max() ?? 0 }
    /// 지금 단에서 몇 번째 단계인지 (단이 바뀌면 처음부터)
    var currentGuideStep: Int {
        guard guideStepRow == guideRowNumber, let g = guideRow(at: guideRowNumber) else { return 0 }
        return min(guideStep, max(0, g.steps.count - 1))
    }

    func hits(at row: Int) -> [ReminderHit] {
        reminders.compactMap { r in r.index(at: row).map { ReminderHit(reminder: r, index: $0) } }
    }
}

// MARK: - 실·바늘 보관함

/// 숫자를 "3" 또는 "2.5"처럼 보기 좋게
func amountString(_ v: Double) -> String {
    v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
}

struct StashYarn: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var color: String = ""
    var weight: String = ""      // 굵기 (예: 합사, DK)
    var amount: Double = 0       // 가진 양
    var unit: String = "볼"      // 볼 · g · m
    var note: String = ""
    var photo: String = ""       // 실 사진 (Documents/Photos 안의 파일 이름)
    var needleSize: String = ""  // 권장 바늘 (예: 4, 3.5~4, 6)
    var needleUnit: String = "mm" // mm · 호
    var title: String { [name, color].filter { !$0.isEmpty }.joined(separator: " ") }
    var needleText: String { needleSize.isEmpty ? "" : needleSize + needleUnit }
}

struct StashNeedle: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var kind: String = "대바늘"  // 대바늘 · 코바늘 · 줄바늘 · 기타
    var size: String = ""
    var note: String = ""
    var title: String { [size, kind].filter { !$0.isEmpty }.joined(separator: " ") }
}

struct Stash: Codable, Hashable {
    var yarns: [StashYarn] = []
    var needles: [StashNeedle] = []
}

/// 작품에 연결한 보관함 실과 쓸 양
struct YarnLink: Codable, Hashable {
    var yarnID: String
    var amount: Double
}

/// 도안함에 저장해 둔 도안: 파일·단별 안내·재료를 담아 두고 바로 작품을 시작해요
struct SavedPattern: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var file: PatternRef?          // PDF(Documents/Patterns) 또는 웹 링크
    var guide: [GuideRow] = []
    var guidePart: String = ""
    var yarn: String = ""
    var needle: String = ""
    var targetRows: Int = 0
    var notes: String = ""
    var createdAt: Double = Date().timeIntervalSince1970 * 1000
    var guideMaxRow: Int { guide.map(\.to).max() ?? 0 }
}

extension SavedPattern {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        file = try? c.decode(PatternRef.self, forKey: .file)
        guide = ((try? c.decode([GuideRow].self, forKey: .guide)) ?? []).filter { $0.from > 0 && $0.to >= $0.from }
        guidePart = (try? c.decode(String.self, forKey: .guidePart)) ?? ""
        yarn = (try? c.decode(String.self, forKey: .yarn)) ?? ""
        needle = (try? c.decode(String.self, forKey: .needle)) ?? ""
        targetRows = max(0, (try? c.decode(Int.self, forKey: .targetRows)) ?? 0)
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
        createdAt = (try? c.decode(Double.self, forKey: .createdAt)) ?? Date().timeIntervalSince1970 * 1000
    }
}

struct BackupFile: Codable {
    var app = "tteugae-note"
    var version = 1
    var exportedAt = ISO8601DateFormatter().string(from: Date())
    var projects: [Project]
    var stash: Stash?
    var patterns: [SavedPattern]?

    init(projects: [Project], stash: Stash? = nil, patterns: [SavedPattern]? = nil) {
        self.projects = projects
        self.stash = stash
        self.patterns = patterns
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        projects = try c.decode([Project].self, forKey: .projects)
        stash = try? c.decode(Stash.self, forKey: .stash)
        patterns = try? c.decode([SavedPattern].self, forKey: .patterns)
    }
}

// MARK: - 너그러운 디코딩 (빠진 값이 있어도 기본값으로 채움)

extension Reminder {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        label = (try? c.decode(String.self, forKey: .label)) ?? ""
        every = (try? c.decode(Int.self, forKey: .every)) ?? 0
        let f = (try? c.decode(Int.self, forKey: .from)) ?? 0
        from = f > 0 ? f : every
        times = Swift.max(0, (try? c.decode(Int.self, forKey: .times)) ?? 0)
        kind = (try? c.decode(String.self, forKey: .kind)) ?? "note"
        stitches = Swift.max(0, (try? c.decode(Int.self, forKey: .stitches)) ?? 0)
    }
}

extension SubCounter {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? "카운터"
        value = Swift.max(0, (try? c.decode(Int.self, forKey: .value)) ?? 0)
        max = Swift.max(0, (try? c.decode(Int.self, forKey: .max)) ?? 0)
        linked = (try? c.decode(Bool.self, forKey: .linked)) ?? false
        offset = Swift.max(0, (try? c.decode(Int.self, forKey: .offset)) ?? 0)
        steps = ((try? c.decode([String].self, forKey: .steps)) ?? []).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        step = Swift.min(Swift.max(0, (try? c.decode(Int.self, forKey: .step)) ?? 0), Swift.max(0, steps.count - 1))
        rowOnFinish = (try? c.decode(Bool.self, forKey: .rowOnFinish)) ?? false
        if !steps.isEmpty { linked = false }
    }
}

extension Project {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date().timeIntervalSince1970 * 1000
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? "이름 없는 작품"
        yarn = (try? c.decode(String.self, forKey: .yarn)) ?? ""
        needle = (try? c.decode(String.self, forKey: .needle)) ?? ""
        targetRows = max(0, (try? c.decode(Int.self, forKey: .targetRows)) ?? 0)
        castOn = max(0, (try? c.decode(Int.self, forKey: .castOn)) ?? 0)
        row = max(0, (try? c.decode(Int.self, forKey: .row)) ?? 0)
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
        let st = (try? c.decode(String.self, forKey: .status)) ?? "active"
        status = ["done", "paused"].contains(st) ? st : "active"
        pausedAt = try? c.decode(Double.self, forKey: .pausedAt)
        doneAt = try? c.decode(Double.self, forKey: .doneAt)
        resumeNote = (try? c.decode(String.self, forKey: .resumeNote)) ?? ""
        changes = (try? c.decode([ChangeNote].self, forKey: .changes)) ?? []
        gauge = (try? c.decode(Gauge.self, forKey: .gauge)) ?? Gauge()
        yarnsUsed = (try? c.decode([YarnUse].self, forKey: .yarnsUsed)) ?? []
        sizeNote = (try? c.decode(String.self, forKey: .sizeNote)) ?? ""
        yarnLinks = (try? c.decode([YarnLink].self, forKey: .yarnLinks)) ?? []
        needleIDs = (try? c.decode([String].self, forKey: .needleIDs)) ?? []
        deducted = (try? c.decode([YarnLink].self, forKey: .deducted)) ?? []
        photos = (try? c.decode([ProjectPhoto].self, forKey: .photos)) ?? []
        guide = ((try? c.decode([GuideRow].self, forKey: .guide)) ?? []).filter { $0.from > 0 && $0.to >= $0.from }
        guidePart = (try? c.decode(String.self, forKey: .guidePart)) ?? ""
        guideStep = max(0, (try? c.decode(Int.self, forKey: .guideStep)) ?? 0)
        guideStepRow = max(0, (try? c.decode(Int.self, forKey: .guideStepRow)) ?? 0)
        reminders = ((try? c.decode([Reminder].self, forKey: .reminders)) ?? []).compactMap { $0.normalized() }
        counters = (try? c.decode([SubCounter].self, forKey: .counters)) ?? []
        log = (try? c.decode([String: Int].self, forKey: .log)) ?? [:]
        pattern = try? c.decode(PatternRef.self, forKey: .pattern)
        createdAt = (try? c.decode(Double.self, forKey: .createdAt)) ?? now
        updatedAt = (try? c.decode(Double.self, forKey: .updatedAt)) ?? now
    }
}


// 빠진 값이 있어도 읽히게
extension Gauge {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stitches = Swift.max(0, (try? c.decode(Int.self, forKey: .stitches)) ?? 0)
        rows = Swift.max(0, (try? c.decode(Int.self, forKey: .rows)) ?? 0)
        needle = (try? c.decode(String.self, forKey: .needle)) ?? ""
    }
}

extension GuideRow {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        from = (try? c.decode(Int.self, forKey: .from)) ?? 0
        to = Swift.max(from, (try? c.decode(Int.self, forKey: .to)) ?? from)
        text = (try? c.decode(String.self, forKey: .text)) ?? ""
        total = Swift.max(0, (try? c.decode(Int.self, forKey: .total)) ?? 0)
    }
}

extension YarnUse {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        color = (try? c.decode(String.self, forKey: .color)) ?? ""
        amount = Swift.max(0, (try? c.decode(Double.self, forKey: .amount)) ?? 0)
        let u = (try? c.decode(String.self, forKey: .unit)) ?? "볼"
        unit = ["볼", "g", "m"].contains(u) ? u : "볼"
    }
}

extension StashYarn {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        color = (try? c.decode(String.self, forKey: .color)) ?? ""
        weight = (try? c.decode(String.self, forKey: .weight)) ?? ""
        amount = Swift.max(0, (try? c.decode(Double.self, forKey: .amount)) ?? 0)
        let u = (try? c.decode(String.self, forKey: .unit)) ?? "볼"
        unit = ["볼", "g", "m"].contains(u) ? u : "볼"
        note = (try? c.decode(String.self, forKey: .note)) ?? ""
        photo = (try? c.decode(String.self, forKey: .photo)) ?? ""
        needleSize = (try? c.decode(String.self, forKey: .needleSize)) ?? ""
        let nu = (try? c.decode(String.self, forKey: .needleUnit)) ?? "mm"
        needleUnit = ["mm", "호"].contains(nu) ? nu : "mm"
    }
}

extension StashNeedle {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        kind = (try? c.decode(String.self, forKey: .kind)) ?? "대바늘"
        size = (try? c.decode(String.self, forKey: .size)) ?? ""
        note = (try? c.decode(String.self, forKey: .note)) ?? ""
    }
}

extension Stash {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        yarns = (try? c.decode([StashYarn].self, forKey: .yarns)) ?? []
        needles = (try? c.decode([StashNeedle].self, forKey: .needles)) ?? []
    }
}
