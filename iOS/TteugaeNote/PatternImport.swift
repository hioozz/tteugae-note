import UIKit
import PDFKit

/// 사진·이미지 도안을 한 쪽짜리 PDF로 바꿔요. (PDF와 똑같이 보고, 필기하고, 쪽을 기억할 수 있게)
enum PatternImport {
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp", "tif", "tiff", "bmp"]

    static func pdfData(fromImage image: UIImage) -> Data? {
        // 사진의 회전 정보를 반영하고, 너무 큰 사진은 줄여요 (긴 변 최대 2400px)
        let maxSide: CGFloat = 2400
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        let target = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let normalized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let page = PDFPage(image: normalized) else { return nil }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        return doc.dataRepresentation()
    }

    static func pdfData(fromImageFile url: URL) -> Data? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
        return pdfData(fromImage: image)
    }
}

extension Store {
    /// PDF·사진 파일을 도안 폴더에 넣고 PatternRef를 돌려줘요
    static func storePatternFile(from source: URL) throws -> PatternRef {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        let title = source.deletingPathExtension().lastPathComponent
        let name = "\(UUID().uuidString).pdf"
        if PatternImport.imageExtensions.contains(source.pathExtension.lowercased()) {
            guard let data = PatternImport.pdfData(fromImageFile: source) else { throw CocoaError(.fileReadCorruptFile) }
            try data.write(to: patternFileURL(name), options: .atomic)
        } else {
            try FileManager.default.copyItem(at: source, to: patternFileURL(name))
        }
        return PatternRef(kind: .pdf, title: title.isEmpty ? "도안" : title, fileName: name, url: nil)
    }

}
