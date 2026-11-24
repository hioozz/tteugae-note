import SwiftUI

/// 가위로 오린 듯 테두리가 살짝 울퉁불퉁한 둥근 사각형.
/// 둘레를 따라 점을 찍고, 각 점을 바깥(법선) 방향으로 조금씩 흔든 뒤 부드럽게 이어요.
/// 웹 버전의 `.wobbly` 버튼과 같은 계산이에요.
struct WobblyRoundedRect: Shape {
    var cornerRadius: CGFloat = 14
    var amplitude: CGFloat = 1.1
    var step: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        let x0 = rect.minX + amplitude, y0 = rect.minY + amplitude
        let x1 = rect.maxX - amplitude, y1 = rect.maxY - amplitude
        let r = max(0, min(cornerRadius, (x1 - x0) / 2, (y1 - y0) / 2))

        typealias Sample = (point: CGPoint, normal: CGVector)
        var segments: [(length: CGFloat, at: (CGFloat) -> Sample)] = []

        func line(_ a: CGPoint, _ b: CGPoint, _ n: CGVector) {
            segments.append((hypot(b.x - a.x, b.y - a.y), { t in
                (CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), n)
            }))
        }
        func arc(_ c: CGPoint, from a0: CGFloat) {
            segments.append((.pi / 2 * r, { t in
                let a = a0 + t * .pi / 2
                return (CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)), CGVector(dx: cos(a), dy: sin(a)))
            }))
        }

        line(CGPoint(x: x0 + r, y: y0), CGPoint(x: x1 - r, y: y0), CGVector(dx: 0, dy: -1))
        arc(CGPoint(x: x1 - r, y: y0 + r), from: -.pi / 2)
        line(CGPoint(x: x1, y: y0 + r), CGPoint(x: x1, y: y1 - r), CGVector(dx: 1, dy: 0))
        arc(CGPoint(x: x1 - r, y: y1 - r), from: 0)
        line(CGPoint(x: x1 - r, y: y1), CGPoint(x: x0 + r, y: y1), CGVector(dx: 0, dy: 1))
        arc(CGPoint(x: x0 + r, y: y1 - r), from: .pi / 2)
        line(CGPoint(x: x0, y: y1 - r), CGPoint(x: x0, y: y0 + r), CGVector(dx: -1, dy: 0))
        arc(CGPoint(x: x0 + r, y: y0 + r), from: .pi)

        let total = segments.reduce(0) { $0 + $1.length }
        guard total > 0 else { return Path(rect) }
        let n = max(12, Int(total / step))
        let f1: CGFloat = 2
        let f2 = max(3, (total / 34).rounded())
        let f3 = max(5, (total / 15).rounded())

        var pts: [CGPoint] = []
        pts.reserveCapacity(n)
        for i in 0..<n {
            var s = total * CGFloat(i) / CGFloat(n)
            let u = 2 * .pi * s / total
            var sample = segments[segments.count - 1].at(1)
            for seg in segments {
                if s <= seg.length {
                    sample = seg.at(seg.length > 0 ? s / seg.length : 0)
                    break
                }
                s -= seg.length
            }
            let k = amplitude * (0.35 * sin(f1 * u + 1.3) + 0.45 * sin(f2 * u + 0.4) + 0.35 * sin(f3 * u + 2.2)) / 1.15
            pts.append(CGPoint(x: sample.point.x + sample.normal.dx * k, y: sample.point.y + sample.normal.dy * k))
        }

        var path = Path()
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]
            path.addCurve(to: p2,
                          control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                          control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        path.closeSubpath()
        return path
    }
}

/// 울퉁불퉁한 모양의 채워진 버튼
struct WobblyPressStyle: ButtonStyle {
    var bg: Color
    var fg: Color
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        let shape = WobblyRoundedRect(cornerRadius: cornerRadius)
        return configuration.label
            .foregroundStyle(fg)
            .background(shape.fill(bg))
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 울퉁불퉁한 테두리의 ‘진행 중 / 완성’ 같은 전환 버튼
struct WobblySegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let items: [(value: Value, label: String)]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { i in
                let item = items[i]
                let selected = item.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = item.value }
                } label: {
                    Text(item.label)
                        .appFont(.subheadline)
                        .foregroundStyle(selected ? Theme.text : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if selected {
                                WobblyRoundedRect(cornerRadius: 11)
                                    .fill(Theme.surface)
                                    .shadow(color: Color.black.opacity(0.06), radius: 3, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(WobblyRoundedRect(cornerRadius: 14).fill(Theme.surface2))
    }
}
