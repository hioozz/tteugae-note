import SwiftUI
import UIKit
import PDFKit
import PencilKit
import PhotosUI
import WebKit

// MARK: - 필기 도구

enum InkTool: String, CaseIterable, Identifiable {
    case pen, redPen, highlighter, eraser
    var id: String { rawValue }

    var label: String {
        switch self {
        case .pen: return "펜"
        case .redPen: return "빨간 펜"
        case .highlighter: return "형광펜"
        case .eraser: return "지우개"
        }
    }
    var symbol: String {
        switch self {
        case .pen, .redPen: return "pencil.tip"
        case .highlighter: return "highlighter"
        case .eraser: return "eraser"
        }
    }
    var swatch: Color {
        switch self {
        case .pen: return Theme.text
        case .redPen: return Color(light: 0xC4553C, dark: 0xE27C60)
        case .highlighter: return Color(light: 0xE9C23B, dark: 0xE9C23B)
        case .eraser: return Theme.muted
        }
    }
    var pkTool: PKTool {
        switch self {
        case .pen: return PKInkingTool(.pen, color: UIColor(hex: 0x2B2420), width: 3)
        case .redPen: return PKInkingTool(.pen, color: UIColor(hex: 0xC4553C), width: 3)
        case .highlighter: return PKInkingTool(.marker, color: UIColor(hex: 0xF2CF4A).withAlphaComponent(0.6), width: 16)
        case .eraser: return PKEraserTool(.vector)
        }
    }
}

// MARK: - 도안 보면서 뜨기 화면 (위: 도안 / 아래: 작은 카운터)

struct PatternScreen: View {
    let projectID: String

    @Environment(Store.self) private var store
    @AppStorage("keepAwake") private var keepAwake = true

    @State private var showMarker = false
    @State private var markerY: CGFloat = 160
    @State private var dragStartY: CGFloat?
    @State private var areaHeight: CGFloat = 400
    @State private var drawMode = false
    @State private var tool: InkTool = .pen
    @State private var undoTick = 0

    var body: some View {
        if let p = store.project(projectID), let ref = p.pattern {
            content(p, ref)
        } else {
            ContentUnavailableView { Label("도안이 없어요", lucide: "doc") }
        }
    }

    private func content(_ p: Project, _ ref: PatternRef) -> some View {
        VStack(spacing: 0) {
            patternBody(ref)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { areaHeight = $0 }
                .overlay(alignment: .top) {
                    if showMarker { marker }
                }
                .clipped()
            if drawMode {
                inkBar
            } else {
                MiniCounterBar(projectID: projectID, project: p)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(ref.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if ref.kind == .pdf {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.snappy) { drawMode.toggle() }
                    } label: {
                        Image(lucide: drawMode ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                    }
                    .accessibilityLabel(drawMode ? "필기 끝내기" : "도안에 필기하기")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.snappy) { showMarker.toggle() }
                    store.setMarker(projectID, showMarker ? Double(markerY) : nil)
                } label: {
                    Image(lucide: showMarker ? "text.line.first.and.arrowtriangle.forward" : "text.alignleft")
                }
                .accessibilityLabel(showMarker ? "줄 표시 끄기" : "줄 표시 켜기")
            }
            if ref.kind == .web, let s = ref.url, let url = URL(string: s) {
                ToolbarItem(placement: .topBarTrailing) {
                    Link(destination: url) { Image(lucide: "safari") }
                        .accessibilityLabel("Safari에서 열기")
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = keepAwake
            if let y = ref.markerY {
                markerY = CGFloat(y)
                showMarker = true
            }
        }
    }

    @ViewBuilder
    private func patternBody(_ ref: PatternRef) -> some View {
        switch ref.kind {
        case .pdf:
            if let name = ref.fileName,
               FileManager.default.fileExists(atPath: Store.patternFileURL(name).path) {
                PDFKitView(url: Store.patternFileURL(name), fileName: name, initialPage: ref.page,
                           drawMode: drawMode, tool: tool, undoTick: undoTick) { page in
                    store.setPatternPage(projectID, page)
                }
            } else {
                ContentUnavailableView {
                    Label("PDF 파일을 찾을 수 없어요", lucide: "doc.questionmark")
                } description: {
                    Text("작품 화면에서 도안을 다시 불러와 주세요.")
                }
            }
        case .web:
            if let s = ref.url, let url = URL(string: s) {
                WebPatternView(url: url)
            } else {
                ContentUnavailableView { Label("링크를 열 수 없어요", lucide: "link") }
            }
        }
    }

    /// 필기 도구 막대 (필기 중에는 카운터 대신 보여요)
    private var inkBar: some View {
        HStack(spacing: 8) {
            ForEach(InkTool.allCases) { t in
                Button { tool = t } label: {
                    Image(lucide: t.symbol)
                        .iconSize(24)
                        .foregroundStyle(t.swatch)
                        .frame(width: 48, height: 48)
                        .background {
                            if tool == t { WobblyRoundedRect(cornerRadius: 14).fill(Theme.accentSoft) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.label)
                .accessibilityAddTraits(tool == t ? [.isSelected] : [])
            }
            Button { undoTick += 1 } label: {
                Image(lucide: "arrow.uturn.backward")
                    .iconSize(22)
                    .frame(width: 44, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.text)
            .accessibilityLabel("필기 되돌리기")
            Spacer(minLength: 4)
            Button {
                withAnimation(.snappy) { drawMode = false }
            } label: {
                Text("완료")
                    .appFont(.body)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
            .buttonStyle(WobblyPressStyle(bg: Theme.accent, fg: Theme.accentInk))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            Theme.surface
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    /// 지금 뜨는 줄을 표시하는 반투명 막대 (위아래로 끌어서 옮기고, 위치를 기억해요)
    private var marker: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Theme.accent.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.accentText.opacity(0.55), lineWidth: 1.5)
            )
            .overlay(alignment: .trailing) {
                Image(lucide: "line.3.horizontal")
                    .iconSize(17)
                    .foregroundStyle(Theme.accentText)
                    .padding(.trailing, 10)
            }
            .frame(height: 30)
            .padding(.horizontal, 6)
            .offset(y: markerY)
            .gesture(
                DragGesture()
                    .onChanged { v in
                        if dragStartY == nil { dragStartY = markerY }
                        markerY = min(max(0, (dragStartY ?? 0) + v.translation.height), max(0, areaHeight - 30))
                    }
                    .onEnded { _ in
                        dragStartY = nil
                        store.setMarker(projectID, Double(markerY))
                    }
            )
            .accessibilityLabel("줄 표시 막대")
            .transition(.opacity)
    }
}

// MARK: - 아래쪽 작은 카운터

struct MiniCounterBar: View {
    let projectID: String
    let project: Project

    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast

    var body: some View {
        let hits = project.hits(at: project.row)
        VStack(spacing: 8) {
            if !hits.isEmpty {
                HStack(spacing: 6) {
                    Image(lucide: "bell.fill")
                    Text(hits.map { $0.reminder.label }.joined(separator: ", ")).lineLimit(1)
                }
                .appFont(.subheadline)
                .foregroundStyle(Theme.warnInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.warnBg, in: Capsule())
            }
            HStack(spacing: 12) {
                Button { change(-1) } label: {
                    Image(lucide: "minus")
                        .iconSize(26)
                        .frame(width: 64, height: 64)
                }
                .buttonStyle(PressStyle(bg: Theme.surface2, fg: Theme.text, radius: 20))
                .accessibilityLabel("1단 빼기")

                VStack(spacing: 0) {
                    Text("\(project.row)")
                        .appFont(size: 40, relativeTo: .title)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(project.row)))
                    Text(project.targetRows > 0 ? "/ \(project.targetRows)단" : "단")
                        .appFont(.caption)
                        .foregroundStyle(Theme.muted)
                }
                .foregroundStyle(Theme.text)
                .frame(minWidth: 72)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("현재 \(project.row)단")

                Button { change(1) } label: {
                    Text("+1단")
                        .appFont(size: 26, relativeTo: .title2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                }
                .buttonStyle(WobblyPressStyle(bg: Theme.accent, fg: Theme.accentInk, cornerRadius: 20))
                .accessibilityLabel("1단 더하기")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            Theme.surface
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func change(_ delta: Int) {
        var result: Store.RowResult?
        withAnimation(.snappy(duration: 0.2)) {
            result = store.changeRow(projectID, by: delta)
        }
        guard let result else { return }
        if result.isHit { Haptics.alert() } else { Haptics.tap() }
        // 반복 알림은 위 배너로 보여 주니, 토스트는 목표 도착 때만 (카운터를 가리지 않게)
        if result.reachedTarget { toast.show("목표 \(project.targetRows)단에 도착했어요!") }
    }
}

// MARK: - PDF 보기 (확대·스크롤, 보던 쪽 기억, 쪽마다 필기)

struct PDFKitView: UIViewRepresentable {
    let url: URL
    let fileName: String
    let initialPage: Int
    var drawMode: Bool
    var tool: InkTool
    var undoTick: Int
    var onPageChange: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(fileName: fileName, onPageChange: onPageChange) }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        let c = context.coordinator
        c.pdfView = view
        c.tool = tool.pkTool
        // 쪽마다 투명한 필기 층을 올려요 (문서를 넣기 전에 정해야 해요)
        view.pageOverlayViewProvider = c
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor(Theme.surface2)
        if let doc = PDFDocument(url: url) {
            view.document = doc
            if doc.pageCount > 0, let page = doc.page(at: min(max(0, initialPage), doc.pageCount - 1)) {
                DispatchQueue.main.async { view.go(to: page) }
            }
        }
        NotificationCenter.default.addObserver(c,
                                               selector: #selector(Coordinator.pageChanged(_:)),
                                               name: .PDFViewPageChanged,
                                               object: view)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        let c = context.coordinator
        c.onPageChange = onPageChange
        c.tool = tool.pkTool
        c.drawMode = drawMode
        if undoTick != c.lastUndoTick {
            c.lastUndoTick = undoTick
            c.undo()
        }
        c.apply()
    }

    static func dismantleUIView(_ view: PDFView, coordinator: Coordinator) {
        coordinator.saveAll()
    }

    final class Coordinator: NSObject, PDFPageOverlayViewProvider, PKCanvasViewDelegate {
        let fileName: String
        var onPageChange: (Int) -> Void
        weak var pdfView: PDFView?
        var tool: PKTool = PKInkingTool(.pen, color: .black, width: 3)
        var drawMode = false
        var lastUndoTick = 0
        private var canvases: [Int: PKCanvasView] = [:]
        private var lastEdited: Int?

        init(fileName: String, onPageChange: @escaping (Int) -> Void) {
            self.fileName = fileName
            self.onPageChange = onPageChange
        }

        @objc func pageChanged(_ note: Notification) {
            guard let view = note.object as? PDFView,
                  let page = view.currentPage,
                  let doc = view.document else { return }
            onPageChange(doc.index(for: page))
        }

        func apply() {
            pdfView?.isInMarkupMode = drawMode
            for c in canvases.values {
                c.tool = tool
                c.isUserInteractionEnabled = drawMode
            }
        }

        func undo() {
            guard let i = lastEdited, let c = canvases[i] else { return }
            c.undoManager?.undo()
        }

        // PDFPageOverlayViewProvider
        func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
            guard let doc = view.document else { return nil }
            let index = doc.index(for: page)
            if let existing = canvases[index] { return existing }
            let canvas = PKCanvasView()
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            canvas.drawingPolicy = .anyInput
            canvas.isScrollEnabled = false
            canvas.tool = tool
            canvas.isUserInteractionEnabled = drawMode
            canvas.tag = index
            if let data = try? Data(contentsOf: Store.inkURL(fileName, page: index)),
               let drawing = try? PKDrawing(data: data) {
                canvas.drawing = drawing
            }
            canvas.delegate = self
            canvases[index] = canvas
            return canvas
        }

        // 필기 층이 화면에 크기를 갖고 나타날 때 저장된 필기를 다시 넣어야 그려져요
        func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) {
            guard let canvas = overlayView as? PKCanvasView else { return }
            let saved = canvas.drawing
            DispatchQueue.main.async {
                canvas.drawing = PKDrawing()
                canvas.drawing = saved
            }
        }

        func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
            guard let canvas = overlayView as? PKCanvasView else { return }
            save(canvas)
            canvases[canvas.tag] = nil
        }

        // PKCanvasViewDelegate: 한 획을 그을 때마다 저장
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            lastEdited = canvasView.tag
            save(canvasView)
        }

        func saveAll() { canvases.values.forEach(save) }

        private func save(_ canvas: PKCanvasView) {
            let url = Store.inkURL(fileName, page: canvas.tag)
            if canvas.drawing.strokes.isEmpty {
                try? FileManager.default.removeItem(at: url)
            } else {
                try? canvas.drawing.dataRepresentation().write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - 웹 도안 보기

struct WebPatternView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.allowsBackForwardNavigationGestures = true
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {}
}

// MARK: - 작품 화면의 도안 칸

struct PatternSection: View {
    let project: Project
    @Binding var photoItem: PhotosPickerItem?
    var onOpen: () -> Void
    var onPickPDF: () -> Void
    var onAddWeb: () -> Void
    var onRemove: () -> Void
    var onSaveToLibrary: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "도안") {
                if project.pattern != nil {
                    Menu {
                        Button(action: onPickPDF) { Label("파일(PDF·이미지)로 바꾸기", lucide: "doc.badge.plus") }
                        PhotosPicker(selection: $photoItem, matching: .images) { Label("사진으로 바꾸기", lucide: "photo") }
                        Button(action: onAddWeb) { Label("웹 링크로 바꾸기", lucide: "link") }
                        if let onSaveToLibrary {
                            Divider()
                            Button(action: onSaveToLibrary) { Label("도안함에 저장", lucide: "book") }
                        }
                        Divider()
                        Button(role: .destructive, action: onRemove) { Label("도안 빼기", lucide: "trash") }
                    } label: {
                        Text("변경")
                            .appFont(.subheadline)
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .background(Theme.surface2, in: Capsule())
                    }
                }
            }

            if let ref = project.pattern {
                Button(action: onOpen) {
                    HStack(spacing: 12) {
                        Image(lucide: ref.kind == .pdf ? "doc.richtext" : "globe")
                            .iconSize(24)
                            .foregroundStyle(Theme.accentText)
                            .frame(width: 44, height: 44)
                            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ref.title).lineLimit(1)
                            Text(ref.kind == .pdf ? "PDF · \(ref.page + 1)쪽부터" : (ref.url ?? ""))
                                .appFont(.caption)
                                .foregroundStyle(Theme.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            Text("보면서 뜨기")
                            Image(lucide: "chevron.right").iconSize(14)
                        }
                        .appFont(.subheadline)
                        .foregroundStyle(Theme.accentText)
                    }
                    .foregroundStyle(Theme.text)
                    .card()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PDF·사진 도안이나 웹 링크를 붙여 두면, 도안을 보면서 단을 세고 도안 위에 바로 필기할 수 있어요.")
                        .appFont(.subheadline)
                        .foregroundStyle(Theme.muted)
                    HStack(spacing: 8) {
                        Button(action: onPickPDF) { Label("파일", lucide: "doc.badge.plus") }
                        PhotosPicker(selection: $photoItem, matching: .images) { Label("사진", lucide: "photo") }
                        Button(action: onAddWeb) { Label("웹 링크", lucide: "link") }
                    }
                    .buttonStyle(ChipStyle())
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WobblyRoundedRect(cornerRadius: 16).fill(Theme.surface))
                .overlay(
                    WobblyRoundedRect(cornerRadius: 16)
                        .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
            }
        }
    }
}
