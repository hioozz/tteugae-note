import SwiftUI
import UIKit

// MARK: - 색 (라이트 / 다크)

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

enum Theme {
    static let bg = Color(light: 0xF6F2EC, dark: 0x1B1613)
    static let surface = Color(light: 0xFFFFFF, dark: 0x251F1A)
    static let surface2 = Color(light: 0xEFE5D9, dark: 0x322921)
    static let line = Color(light: 0xE5D7C8, dark: 0x3B3129)
    static let text = Color(light: 0x2B2420, dark: 0xF2E9E0)
    static let muted = Color(light: 0x7A6B60, dark: 0xB0A093)
    static let accent = Color(light: 0xEAC9C9, dark: 0xEAC9C9)
    static let accentInk = Color(light: 0x4A2626, dark: 0x1B1613)
    static let accentSoft = Color(light: 0xF8EAEA, dark: 0x3E2A2A)
    static let accentText = Color(light: 0x8A4545, dark: 0xF0D2D2)
    static let sage = Color(light: 0x4F7360, dark: 0x9FC4AB)
    static let sageSoft = Color(light: 0xDCE8DF, dark: 0x22332A)
    static let warnBg = Color(light: 0xF3E3C1, dark: 0x3A2F12)
    static let warnInk = Color(light: 0x5E4500, dark: 0xF4D98D)
    static let warnLine = Color.clear   // 노란 상자는 테두리 없이
    static let danger = Color(light: 0xB23A3A, dark: 0xF09A9A)
}

// MARK: - 진동

enum Haptics {
    private static var enabled: Bool { UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true }

    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func alert() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - 토스트

@Observable
final class ToastCenter {
    var message: String?
    private var task: Task<Void, Never>?

    func show(_ text: String) {
        message = text
        task?.cancel()
        task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .appFont(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.bg)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.text, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - 공용 스타일

struct PressStyle: ButtonStyle {
    var bg: Color
    var fg: Color
    var radius: CGFloat = 28

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return configuration.label
            .foregroundStyle(fg)
            .background(bg, in: shape)
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ChipBody(configuration: configuration)
    }

    private struct ChipBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .appFont(.subheadline)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(Theme.surface2, in: Capsule())
                .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
        }
    }
}

struct CardModifier: ViewModifier {
    var fill: Color = Theme.surface
    var stroke: Color = Theme.line

    func body(content: Content) -> some View {
        let shape = WobblyRoundedRect(cornerRadius: 18)   // 손으로 오린 듯한 테두리
        return content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(fill))
            .overlay(shape.stroke(stroke, lineWidth: 1))
    }
}

extension View {
    func card(fill: Color = Theme.surface, stroke: Color = Theme.line) -> some View {
        modifier(CardModifier(fill: fill, stroke: stroke))
    }
}

struct Pill: View {
    let text: String
    var fg: Color = Theme.accentText
    var bg: Color = Theme.accentSoft

    var body: some View {
        Text(text)
            .appFont(.subheadline)
            .monospacedDigit()
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(bg, in: Capsule())
    }
}

struct ProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surface2)
                Capsule().fill(Theme.sage).frame(width: max(0, g.size.width * value))
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("진행률")
        .accessibilityValue("\(Int((value * 100).rounded()))%")
    }
}

struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            Text(title).appFont(.headline).foregroundStyle(Theme.text)
            Spacer()
            trailing
        }
    }
}

struct HintBox: View {
    let text: String

    var body: some View {
        Text(text)
            .appFont(.subheadline)
            .foregroundStyle(Theme.muted)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WobblyRoundedRect(cornerRadius: 16).fill(Theme.surface))
            .overlay(
                WobblyRoundedRect(cornerRadius: 16)
                    .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
    }
}

/// 숫자만 받는 입력칸 (0은 빈칸으로 보여요)
struct NumberField: View {
    let placeholder: String
    @Binding var value: Int

    var body: some View {
        TextField(placeholder, text: Binding(
            get: { value == 0 ? "" : String(value) },
            set: { value = min(99_999, Int($0.filter(\.isNumber)) ?? 0) }
        ))
        .keyboardType(.numberPad)
    }
}

/// 비어 있는 화면: 로고 그림 + 제목 + 설명 + (선택) 버튼을 가운데 정렬로
struct EmptyStateView: View {
    let title: String
    var message: String = ""
    var note: String = ""
    var buttonTitle: String? = nil
    var buttonIcon: String = "plus"
    var action: (() -> Void)? = nil
    var secondary: AnyView? = nil

    var body: some View {
        VStack(spacing: 14) {
            KnittingCatAnimation(size: 150)
            Text(title)
                .appFont(.title3)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            if !message.isEmpty {
                Text(message)
                    .appFont(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            if !note.isEmpty {
                Text(note)
                    .appFont(.caption)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            if let buttonTitle, let action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: buttonIcon)
                        .appFont(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(WobblyPressStyle(bg: Theme.accent, fg: Theme.accentInk))
                .padding(.top, 6)
            }
            if let secondary { secondary }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }
}

/// 뜨개질하는 픽셀 고양이 (4장, 0.3초마다 넘김). 동작 줄이기를 켜면 멈춘 그림으로
struct KnittingCatAnimation: View {
    var size: CGFloat = 150
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                frame(0)
            } else {
                TimelineView(.periodic(from: .now, by: 0.3)) { ctx in
                    frame(Int(ctx.date.timeIntervalSinceReferenceDate / 0.3) % 4)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func frame(_ i: Int) -> some View {
        Image("KnitCat\(i)")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}
