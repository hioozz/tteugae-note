import UIKit
import PDFKit
import Vision

/// 도안 PDF에서 글자를 읽어요. 글자가 들어 있는 PDF는 그대로 읽고, 그림으로 된 PDF는 글자 인식(OCR)을 해요.
/// 모두 기기 안에서 처리해요.
enum GuideReader {
    static let maxPages = 8

    static func read(pdfURL: URL) async -> GuideParser.Result {
        await Task.detached(priority: .userInitiated) {
            guard let doc = PDFDocument(url: pdfURL) else { return GuideParser.Result() }
            var lines: [GuideParser.Line] = []
            for i in 0..<min(doc.pageCount, maxPages) {
                guard let page = doc.page(at: i) else { continue }
                lines += pageLines(page, index: i)
            }
            return GuideParser.parse(lines)
        }.value
    }

    private static func pageLines(_ page: PDFPage, index: Int) -> [GuideParser.Line] {
        let text = page.string ?? ""
        if text.contains("단") || text.range(of: #"\b(R|Rnd|Row)\s*\d"#, options: .regularExpression) != nil {
            // 글자가 들어 있는 PDF: 줄 순서대로 (위치는 몰라요)
            return text.components(separatedBy: .newlines).enumerated().map {
                GuideParser.Line(text: $1, x: nil, y: Double(index) + Double($0) / 10_000)
            }
        }
        return ocr(page, index: index)
    }

    private static func ocr(_ page: PDFPage, index: Int) -> [GuideParser.Line] {
        let box = page.bounds(for: .mediaBox)
        let scale = min(3, 2400 / max(box.width, box.height, 1))
        let image = page.thumbnail(of: CGSize(width: box.width * scale, height: box.height * scale), for: .mediaBox)
        guard let cg = image.cgImage else { return [] }
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.recognitionLanguages = ["ko-KR", "en-US"]
        req.usesLanguageCorrection = true
        do { try VNImageRequestHandler(cgImage: cg).perform([req]) } catch { return [] }
        return (req.results ?? []).compactMap { o in
            guard let s = o.topCandidates(1).first?.string else { return nil }
            let b = o.boundingBox
            // 쪽마다 칸 위치를 따로 보려고 x에 쪽 번호를 더해요
            return GuideParser.Line(text: s, x: Double(b.minX) + Double(index) * 10, y: Double(index) + Double(1 - b.maxY))
        }
    }
}
