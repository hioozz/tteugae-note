import SwiftUI

// MARK: - 완성한 작품 모아보기 (예전 '제작 기록 모아보기'를 합쳤어요)

struct DoneProjectsView: View {
    /// 작품을 고르면 그 작품 id를 알려 줘요 (목록 화면이 열어요)
    var onOpen: (String) -> Void

    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var done: [Project] {
        store.projects.filter(\.isDone).sorted { $0.doneDate > $1.doneDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if done.isEmpty {
                    EmptyStateView(title: "아직 완성한 작품이 없어요",
                                   message: "다 뜬 작품은 작품 화면 맨 아래\n‘완성으로 표시’를 눌러 주세요.\n사진과 제작 기록이 여기에 모여요.")
                        .containerRelativeFrame(.vertical) { h, _ in h * 0.9 }
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(summary)
                            .appFont(.subheadline)
                            .foregroundStyle(Theme.muted)
                        ForEach(done) { p in
                            Button {
                                onOpen(p.id)
                                dismiss()
                            } label: {
                                DoneCard(project: p)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("완성한 작품")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
        }
    }

    private var summary: String {
        let year = Calendar.current.component(.year, from: Date())
        let thisYear = done.filter { Calendar.current.component(.year, from: $0.doneDate) == year }.count
        return "지금까지 \(done.count)개 완성" + (thisYear > 0 && thisYear != done.count ? " · 올해 \(thisYear)개" : "")
    }
}

struct DoneCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let ph = project.photos.last {
                DonePhoto(fileName: ph.fileName)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(project.name).appFont(.headline)
                    Spacer(minLength: 8)
                    Pill(text: "\(project.row)단", fg: Theme.sage, bg: Theme.sageSoft)
                }
                Text("\(project.doneDate.formatted(.dateTime.year().month().day())) 완성 · \(project.daysTaken)일 걸림")
                    .appFont(.subheadline)
                    .foregroundStyle(Theme.muted)
                if !project.meta.isEmpty {
                    Text(project.meta).appFont(.subheadline).foregroundStyle(Theme.muted)
                }
            }
            if project.hasRecord {
                VStack(alignment: .leading, spacing: 6) {
                    if !project.gauge.isEmpty { line("ruler", "게이지 " + project.gauge.text) }
                    if !project.yarnsUsed.isEmpty { line("circle.dotted", project.yarnsUsed.map(\.text).joined(separator: ", ")) }
                    if !project.sizeNote.isEmpty { line("tshirt", project.sizeNote) }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface2.opacity(0.6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .foregroundStyle(Theme.text)
        .card(stroke: .clear)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        .contentShape(Rectangle())
    }

    private func line(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(lucide: symbol).iconSize(16).foregroundStyle(Theme.accentText).frame(width: 18)
            Text(text).appFont(.subheadline).lineLimit(3)
        }
    }
}

/// 완성작 카드 위의 넓은 사진
private struct DonePhoto: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Theme.surface2
            if let image { Image(uiImage: image).resizable().scaledToFill() }
        }
        .frame(height: 190)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task(id: fileName) { image = await PhotoFiles.thumbnail(fileName) }
    }
}
