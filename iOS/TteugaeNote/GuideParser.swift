import Foundation

/// 도안 글에서 "1단: …", "3단-10단: …" 같은 줄을 찾아 단별 안내로 바꿔요.
/// PDF 글자든, 사진에서 읽은 글자(OCR)든 같은 방식으로 다뤄요.
enum GuideParser {
    /// 읽어 온 한 줄. x·y는 쪽 안의 위치(0~1, 위가 0)이고, 모르면 nil이에요.
    struct Line {
        var text: String
        var x: Double? = nil
        var y: Double = 0
    }

    struct Part: Hashable {
        var name: String
        var rows: [GuideRow]
    }

    struct Result {
        var parts: [Part] = []
        var yarn: String = ""
        var needle: String = ""
        var isEmpty: Bool { parts.allSatisfy { $0.rows.isEmpty } }
    }

    // MARK: 줄 나누기

    private static let rowPrefix = try! NSRegularExpression(
        pattern: #"^\s*(?:(R|Rnd|Row|Round)\s*)?(\d{1,3})\s*(단)?\s*(?:[-~]\s*(\d{1,3})\s*(단)?)?\s*[:：.)\]]?\s*"#,
        options: [.caseInsensitive])
    private static let totalRegex = try! NSRegularExpression(pattern: #"[(（]?\s*총\s*(\d{1,4})\s*코?\s*[)）]?"#)

    static func normalize(_ s: String) -> String {
        var t = s
        for (a, b) in [("：", ":"), ("～", "~"), ("〜", "~"), ("–", "-"), ("—", "-"), ("－", "-"), ("−", "-"), ("‐", "-"), ("‑", "-"), ("ㅡ", "-"), ("ー", "-"), ("＊", "*"), ("×", "*"), ("，", ","), ("（", "("), ("）", ")")] {
            t = t.replacingOccurrences(of: a, with: b)
        }
        // 숫자 사이의 x는 곱하기 (예: 짧은뜨기1x4)
        t = t.replacingOccurrences(of: #"(\d)\s*[xX]\s*(\d)"#, with: "$1*$2", options: .regularExpression)
        // 글자 인식이 뜨기 이름 사이에 넣은 띄어쓰기를 지워요 (예: 짧 은 뜨 기 → 짧은뜨기)
        for w in ["한길긴뜨기", "두길긴뜨기", "긴뜨기", "짧은뜨기", "빼뜨기", "사슬뜨기", "사슬", "기둥코", "늘려", "모아", "늘리기", "줄이기"] {
            let pattern = w.map { String($0) }.joined(separator: #"\s*"#)
            t = t.replacingOccurrences(of: pattern, with: w, options: .regularExpression)
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 줄 머리의 단 번호. (시작, 끝, 나머지 글)
    static func rowHead(_ line: String) -> (from: Int, to: Int, rest: String)? {
        let ns = line as NSString
        guard let m = rowPrefix.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let hasEnglish = m.range(at: 1).location != NSNotFound
        let hasDan = m.range(at: 3).location != NSNotFound || m.range(at: 5).location != NSNotFound
        guard hasEnglish || hasDan, let a = Int(ns.substring(with: m.range(at: 2))) else { return nil }
        var b = a
        if m.range(at: 4).location != NSNotFound, let v = Int(ns.substring(with: m.range(at: 4))) { b = v }
        guard a > 0, b >= a, b - a < 500 else { return nil }
        var rest = ns.substring(from: m.range.location + m.range.length).trimmingCharacters(in: .whitespaces)
        // 사이 기호를 못 알아본 경우: "3단 ? 10단: …" → 남은 글이 "10단:"으로 시작하면 범위로 봐요
        if b == a, let r = rest.range(of: #"^\D{0,2}\s*(\d{1,3})\s*단\s*[:.)]?\s*"#, options: .regularExpression) {
            let num = Int(rest[r].filter(\.isNumber)) ?? 0
            if num > a && num - a < 500 { b = num; rest = String(rest[r.upperBound...]) }
        }
        // "1단 늘리기"처럼 단 번호가 아닌 말이 이어지면 건너뛰어요: 구분자(: . ) 등)나 뜨기 기호가 있어야 해요
        let sepRange = NSRange(location: m.range.location, length: m.range.length)
        let head = ns.substring(with: sepRange)
        if !head.contains(where: { ":.)]".contains($0) }) && !rest.isEmpty
            && !(rest.contains(",") || (rest.contains(where: \.isNumber) && looksLikeStitches(rest))) {
            return nil
        }
        return (a, b, rest)
    }

    private static let stitchWords = ["사슬", "짧은", "긴뜨기", "빼뜨기", "뜨기", "기둥", "늘려", "늘리", "모아", "줄여", "코", "겉", "안", "바늘",
                                      "ch", "sc", "dc", "hdc", "tr", "sl", "inc", "dec", "k", "p"]
    static func looksLikeStitches(_ s: String) -> Bool {
        let l = s.lowercased()
        return l.contains(",") || stitchWords.contains { l.contains($0) }
    }

    private static func hasHangul(_ s: String) -> Bool {
        s.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
    }

    // MARK: 읽기

    static func parse(_ raw: [Line]) -> Result {
        var lines = raw.map { Line(text: normalize($0.text), x: $0.x, y: $0.y) }.filter { !$0.text.isEmpty }

        // 위치를 알면, 단 줄이 있는 세로 칸만 남기고 그 칸 순서대로 읽어요 (그림 속 글자 빼기)
        let rowXs = lines.compactMap { l in rowHead(l.text) != nil ? l.x : nil }.sorted()
        if !rowXs.isEmpty {
            var columns: [Double] = []
            for x in rowXs where columns.last.map({ x - $0 > 0.06 }) ?? true { columns.append(x) }
            func column(_ l: Line) -> Int? {
                guard let x = l.x else { return 0 }
                let best = columns.enumerated().min { abs($0.element - x) < abs($1.element - x) }!
                return abs(best.element - x) <= 0.05 ? best.offset : nil
            }
            lines = lines.compactMap { l in column(l).map { (l, $0) } }
                .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0.y < $1.0.y }
                .map(\.0)
        }

        var result = Result()
        var parts: [Part] = []
        var current = Part(name: "", rows: [])
        var freeText: [String] = []      // 단 번호 없이 적힌 줄 (예: 체리 "사슬4, 빼뜨기")
        var canContinue = false

        func flush() {
            if current.rows.isEmpty, !freeText.isEmpty {
                current.rows = [GuideRow(from: 1, to: 1, text: freeText.joined(separator: " "))]
            }
            if !current.rows.isEmpty { parts.append(current) }
            freeText = []
        }

        for l in lines {
            let t = l.text
            if let h = rowHead(t) {
                if !freeText.isEmpty, current.rows.isEmpty { freeText = [] }
                current.rows.append(GuideRow(from: h.from, to: h.to, text: h.rest))
                canContinue = true
                continue
            }
            // 사용한 실 · 바늘
            if let colon = t.firstIndex(where: { $0 == ":" }) {
                let key = t[..<colon].lowercased()
                let value = t[t.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                if !value.isEmpty && key.count <= 12 {
                    if key.contains("실") || key.contains("yarn") {
                        if result.yarn.isEmpty { result.yarn = String(value.prefix(60)) }
                        canContinue = false; continue
                    }
                    if key.contains("바늘") || key.contains("needle") || key.contains("hook") {
                        if result.needle.isEmpty { result.needle = String(value.prefix(40)) }
                        canContinue = false; continue
                    }
                }
            }
            // 목록 기호로 시작하면 설명이라 건너뛰어요
            if let f = t.first, "-•·*※▶►".contains(f) { canContinue = false; continue }

            let lastText = current.rows.last?.text ?? freeText.last ?? ""
            let endsOpen = lastText.hasSuffix(",") || lastText.hasSuffix("(") || lastText.hasSuffix("→")
                || lastText.filter({ $0 == "(" }).count > lastText.filter({ $0 == ")" }).count
            if canContinue && (endsOpen || (t.first == "(" ) || (t.first.map { $0.isNumber } == false && looksLikeStitches(t) && t.contains(","))) {
                if !current.rows.isEmpty { current.rows[current.rows.count - 1].text += " " + t }
                else { freeText[freeText.count - 1] += " " + t }
                continue
            }
            // 짧은 제목 줄이면 새 부분 (예: 푸딩, 체리, 몸통)
            if t.count <= 14 && !t.contains(",") && (hasHangul(t) || t.contains(where: \.isLetter)) && !looksLikeStitchLine(t) {
                flush()
                current = Part(name: t, rows: [])
                canContinue = false
                continue
            }
            // 제목 아래 단 번호 없는 뜨기 줄
            if !current.name.isEmpty && current.rows.isEmpty && looksLikeStitches(t) {
                freeText.append(t)
                canContinue = true
                continue
            }
            canContinue = false
        }
        flush()

        // 글자 정리: 총 코 수 떼어 내기
        for i in parts.indices {
            for j in parts[i].rows.indices {
                var r = parts[i].rows[j]
                let ns = r.text as NSString
                if let m = totalRegex.firstMatch(in: r.text, range: NSRange(location: 0, length: ns.length)),
                   let n = Int(ns.substring(with: m.range(at: 1))) {
                    r.total = n
                    r.text = ns.replacingCharacters(in: m.range, with: "")
                }
                r.text = tidy(r.text)
                parts[i].rows[j] = r
            }
            parts[i].rows.removeAll { $0.text.isEmpty }
            if parts[i].name.isEmpty { parts[i].name = "도안" }
        }
        result.parts = parts.filter { !$0.rows.isEmpty }
        return result
    }

    private static func looksLikeStitchLine(_ t: String) -> Bool {
        // "사슬4"처럼 숫자가 붙은 뜨기 이름이면 제목이 아니에요
        t.range(of: #"\d"#, options: .regularExpression) != nil && looksLikeStitches(t)
    }

    /// 띄어쓰기·쉼표를 가지런히
    static func tidy(_ s: String) -> String {
        var t = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s*,\s*"#, with: ", ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\(\s+"#, with: "(", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s+\)"#, with: ")", options: .regularExpression)
        t = t.trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
        return t
    }

    // MARK: 단계 나누기

    /// 한 단의 글을 뜨는 순서대로 나눠요. 괄호 안은 한 단계로 묶어요.
    /// "사슬2, 짧은뜨기1*5" → ["사슬 2", "짧은뜨기 1 × 5"]
    static func steps(_ text: String) -> [String] {
        var out: [String] = []
        var cur = ""
        var depth = 0
        for ch in text {
            if ch == "(" { depth += 1 }
            if ch == ")" { depth = max(0, depth - 1) }
            if depth == 0 && (ch == "," || ch == "→") {
                out.append(cur); cur = ""
            } else {
                cur.append(ch)
            }
        }
        out.append(cur)
        return out.map(pretty).filter { !$0.isEmpty }.map { String($0.prefix(60)) }
    }

    /// "짧은뜨기1*4" → "짧은뜨기 1 × 4"
    static func pretty(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespaces)
        t = t.replacingOccurrences(of: #"([가-힣])(\d)"#, with: "$1 $2", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s*\*\s*"#, with: " × ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return t
    }
}
