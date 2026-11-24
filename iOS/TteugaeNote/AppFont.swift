import SwiftUI
import UIKit
import CoreText

/// Pretendard (Fonts/Pretendard-Regular.otf, SIL OFL 1.1)
/// Info.plist 없이 앱이 켜질 때 직접 등록해요.
enum AppFont {
    static let name = "Pretendard-Regular"
    /// 글자 크기 배율 (Pretendard는 기본 크기 그대로)
    static let scale: CGFloat = 1.0

    static func register() {
        let url = Bundle.main.url(forResource: "Pretendard-Regular", withExtension: "otf")
            ?? Bundle.main.url(forResource: "Pretendard-Regular", withExtension: "otf", subdirectory: "Fonts")
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
        nav.largeTitleTextAttributes = [.font: large, .kern: large.pointSize * trackingRatio]
        nav.titleTextAttributes = [.font: title, .kern: title.pointSize * trackingRatio]
        UISegmentedControl.appearance().setTitleTextAttributes([.font: segment, .kern: segment.pointSize * trackingRatio], for: .normal)
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

// MARK: - 자간 (모든 글자 -2%)

extension AppFont {
    /// 자간: 글자 크기의 -2%
    static let trackingRatio: CGFloat = -0.02
}

/// 글꼴과 자간(-2%)을 함께 적용해요. 다이내믹 타입으로 글자가 커지면 자간도 같이 커져요.
private struct AppFontModifier: ViewModifier {
    let size: CGFloat
    let style: Font.TextStyle
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let scaled = UIFontMetrics(forTextStyle: style.uiKit)
            .scaledValue(for: size * AppFont.scale, compatibleWith: UITraitCollection(preferredContentSizeCategory: dynamicTypeSize.uiKit))
        content
            .font(.custom(AppFont.name, size: size * AppFont.scale, relativeTo: style))
            .tracking(scaled * AppFont.trackingRatio)
    }
}

extension View {
    func appFont(_ style: Font.TextStyle) -> some View {
        modifier(AppFontModifier(size: AppFont.size(for: style), style: style))
    }

    func appFont(size: CGFloat, relativeTo style: Font.TextStyle = .body) -> some View {
        modifier(AppFontModifier(size: size, style: style))
    }
}

private extension Font.TextStyle {
    var uiKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

private extension DynamicTypeSize {
    var uiKit: UIContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}
