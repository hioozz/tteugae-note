import SwiftUI

// MARK: - 앱 스타일 입력 화면 부품
// 시스템 설정 화면(Form) 대신 쓰는 부품이에요.
// 배경 · 하얀 몽글 카드 · 둥근 입력칸 · 알약 고르기로 앱의 다른 화면과 같은 느낌을 내요.
// 키보드, 사진 고르기, 삭제 확인창, 켜고 끄는 스위치는 시스템 것을 그대로 써요.

/// 입력 화면 전체 틀: 스크롤 + 앱 배경
struct AppForm<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .foregroundStyle(Theme.text)
    }
}

/// 제목 + 하얀 카드 + 아래 도움말
struct FormSection<Content: View, Trailing: View>: View {
    var title: String?
    var footer: String?
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if title != nil || Trailing.self != EmptyView.self {
                HStack(alignment: .firstTextBaseline) {
                    if let title { Text(title).appFont(.headline) }
                    Spacer(minLength: 8)
                    trailing.appFont(.subheadline)
                }
                .padding(.horizontal, 4)
            }
            VStack(alignment: .leading, spacing: 14) {
                content
            }
            .card()
            if let footer, !footer.isEmpty {
                Text(verbatim: footer)
                    .appFont(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }
}

extension FormSection where Trailing == EmptyView {
    init(title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.trailing = EmptyView()
        self.content = content()
    }
}

/// 카드 안의 구분선
struct FormDivider: View {
    var body: some View {
        Rectangle().fill(Theme.line).frame(height: 1).opacity(0.7)
    }
}

/// 입력칸 모양: 연한 바탕 + 둥근 모서리 + 얇은 테두리
struct FieldBox: ViewModifier {
    var vertical: CGFloat = 11
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        content
            .appFont(.body)
            .foregroundStyle(Theme.text)
            .tint(Theme.accentText)
            .padding(.horizontal, 12)
            .padding(.vertical, vertical)
            .background(Theme.bg, in: shape)
            .overlay(shape.stroke(Theme.line, lineWidth: 1))
    }
}

extension View {
    func fieldBox(vertical: CGFloat = 11) -> some View { modifier(FieldBox(vertical: vertical)) }
}

/// 글자 입력칸 (자리표시 글자는 그대로 보여요: * 같은 기호도 기울지 않게)
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var lines: ClosedRange<Int>? = nil

    init(_ placeholder: String, text: Binding<String>, lines: ClosedRange<Int>? = nil) {
        self.placeholder = placeholder
        _text = text
        self.lines = lines
    }

    var body: some View {
        Group {
            if let lines {
                TextField("", text: $text, prompt: prompt, axis: .vertical).lineLimit(lines)
            } else {
                TextField("", text: $text, prompt: prompt)
            }
        }
        .fieldBox()
    }

    private var prompt: Text {
        Text(verbatim: placeholder).foregroundStyle(Theme.muted.opacity(0.75))
    }
}

/// 위에 작은 이름표가 붙은 칸
struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).appFont(.subheadline).foregroundStyle(Theme.muted)
            content
        }
    }
}

/// 왼쪽 이름 + 오른쪽 숫자칸 한 줄
struct InlineNumberRow: View {
    let label: String
    let placeholder: String
    @Binding var value: Int
    var suffix: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(label).appFont(.body)
            Spacer()
            NumberField(placeholder: placeholder, value: $value)
                .multilineTextAlignment(.trailing)
                .frame(width: 84)
                .fieldBox(vertical: 8)
            if let suffix { Text(suffix).appFont(.body).foregroundStyle(Theme.muted) }
        }
    }
}

/// 알약 모양으로 하나 고르기 (기본 선택 버튼 대신)
struct ChoiceChips<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    var fill = false   // true면 칸을 가로로 꽉 채워요

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options.indices, id: \.self) { i in
                let o = options[i]
                let on = o.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.15)) { selection = o.value }
                    Haptics.tap()
                } label: {
                    Text(o.label)
                        .appFont(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(on ? Theme.accentInk : Theme.text)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .frame(maxWidth: fill ? .infinity : nil)
                        .background(on ? Theme.accent : Theme.surface2, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected] : [])
            }
        }
    }
}

/// 이름(+작은 설명) + 켜고 끄는 스위치
struct ToggleRow: View {
    let title: String
    var detail: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).appFont(.body)
                if let detail, !detail.isEmpty {
                    Text(detail).appFont(.caption).foregroundStyle(Theme.muted)
                }
            }
        }
        .tint(Theme.sage)
    }
}

/// 점선 테두리의 "+ 추가" 버튼
struct AddRowButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, lucide: "plus")
                .appFont(.subheadline)
                .foregroundStyle(Theme.accentText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 줄 오른쪽의 작은 빼기 버튼 (밀어서 지우기 대신)
struct RemoveRowButton: View {
    var label = "삭제"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(lucide: "minus.circle")
                .iconSize(24)
                .foregroundStyle(Theme.muted)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// 화면 맨 아래 빨간 글자 삭제 버튼
struct DangerButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .appFont(.body)
                .foregroundStyle(Theme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(WobblyRoundedRect(cornerRadius: 18).fill(Theme.surface))
                .overlay(WobblyRoundedRect(cornerRadius: 18).stroke(Theme.line, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 카드 안의 글자 버튼 (예: 단별로 나누기, 다시 세기)
struct InlineActionButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage { Label(title, lucide: systemImage) } else { Text(title) }
            }
            .appFont(.subheadline)
        }
        .buttonStyle(ChipStyle())
    }
}
