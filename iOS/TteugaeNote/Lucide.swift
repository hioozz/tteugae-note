import SwiftUI

// MARK: - Lucide 아이콘 (https://lucide.dev, ISC 라이선스)
// 아이콘 파일은 Assets.xcassets/Lucide/lucide-이름 에 SVG로 들어 있어요.
// 새 아이콘이 필요하면 lucide.dev에서 이름을 찾아 같은 방식으로 넣고 아래 표에 이어 적으면 돼요.
// 코드에서는 예전 SF Symbols 이름을 그대로 써도 아래 표에서 Lucide 이름으로 바꿔 줘요.

enum Lucide {
    /// 예전 SF Symbols 이름 → Lucide 이름
    static let map: [String: String] = [
        "plus": "plus",
        "minus": "minus",
        "photo": "image",
        "photo.on.rectangle": "images",
        "link": "link",
        "doc": "file",
        "doc.badge.plus": "file-plus",
        "doc.richtext": "file-text",
        "doc.questionmark": "file-question",
        "doc.text.viewfinder": "scan-text",
        "arrow.down.doc": "file-down",
        "camera": "camera",
        "arrow.uturn.backward": "undo-2",
        "arrow.counterclockwise": "rotate-ccw",
        "trash": "trash-2",
        "shippingbox": "package",
        "play.fill": "play",
        "pause": "pause",
        "pause.circle": "circle-pause",
        "ellipsis": "ellipsis",
        "book": "book-open",
        "square.and.arrow.up": "share",
        "square.and.arrow.down": "download",
        "square.and.pencil": "square-pen",
        "gearshape": "settings",
        "checkmark": "check",
        "checkmark.seal": "badge-check",
        "checkmark.circle.fill": "circle-check",
        "bell.fill": "bell",
        "xmark": "x",
        "minus.circle": "circle-minus",
        "chevron.right": "chevron-right",
        "chevron.left": "chevron-left",
        "text.line.first.and.arrowtriangle.forward": "list-ordered",
        "text.alignleft": "align-left",
        "safari": "compass",
        "globe": "globe",
        "pencil": "pencil",
        "pencil.tip": "pen",
        "pencil.tip.crop.circle": "pencil",
        "pencil.tip.crop.circle.fill": "pencil-off",
        "highlighter": "highlighter",
        "eraser": "eraser",
        "line.diagonal": "slash",
        "line.3.horizontal": "menu",
        "circle.dotted": "circle-dashed",
        "ruler": "ruler",
        "tshirt": "shirt",
    ]

    static func assetName(_ name: String) -> String {
        "lucide-" + (map[name] ?? name)
    }
}

extension Image {
    /// Lucide 아이콘 (기본 18pt, 글자색을 따라가요). SF Symbols 이름을 넣어도 돼요.
    init(lucide name: String) {
        self = Image(Lucide.assetName(name)).renderingMode(.template)
    }
}

extension Image {
    /// 아이콘 크기 지정 (예전 .font(.system(size:)) 대신)
    func iconSize(_ size: CGFloat) -> some View {
        resizable().scaledToFit().frame(width: size, height: size)
    }
}

extension Label where Title == Text, Icon == Image {
    init(_ titleKey: LocalizedStringKey, lucide name: String) {
        self.init { Text(titleKey) } icon: { Image(lucide: name) }
    }

    init<S: StringProtocol>(_ title: S, lucide name: String) {
        self.init { Text(title) } icon: { Image(lucide: name) }
    }
}
