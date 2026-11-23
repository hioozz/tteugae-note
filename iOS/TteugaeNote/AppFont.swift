import SwiftUI
import UIKit
import CoreText

/// 온글잎 박다현체 (Fonts/OwnglyphPDH.ttf)
/// Info.plist 없이 앱이 켜질 때 직접 등록해요.
enum AppFont {
    static let name = "Ownglyph_PDH-Rg"
    /// 박다현체는 같은 크기에서 글자가 작게 보여서 조금 키워요
    static let scale: CGFloat = 1.12

    static func register() {
        let url = Bundle.main.url(forResource: "OwnglyphPDH", withExtension: "ttf")
            ?? Bundle.main.url(forResource: "OwnglyphPDH", withExtension: "ttf", subdirectory: "Fonts")
        guard let url else {
            print("폰트 파일을 찾지 못했어요")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            print("폰트 등록 실패: \(String(describing: error?.takeRetainedValue()))")
        }
    }

    /// 내비게이션 제목, 탭 전환 버튼처럼 UIKit이 그리는 글자에도 적용
    static func configureUIKit() {
        guard let large = UIFont(name: name, size: 34 * scale),
              let title = UIFont(name: name, size: 18 * scale),
              let segment = UIFont(name: name, size: 15 * scale) else { return }
        let nav = UINavigationBar.appearance()
        nav.largeTitleTextAttributes = [.font: large]
        nav.titleTextAttributes = [.font: title]
        UISegmentedControl.appearance().setTitleTextAttributes([.font: segment], for: .normal)
    }

    static func size(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}

extension Font {
    /// 앱 글꼴로 된 텍스트 스타일 (다이내믹 타입 크기 조절도 따라가요)
    static func app(_ style: Font.TextStyle) -> Font {
        .custom(AppFont.name, size: AppFont.size(for: style) * AppFont.scale, relativeTo: style)
    }

    static func app(size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(AppFont.name, size: size * AppFont.scale, relativeTo: style)
    }
}
