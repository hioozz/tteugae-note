import SwiftUI
import PhotosUI

/// 소수점 양 입력칸 (0은 빈칸)
struct DecimalField: View {
    let placeholder: String
    @Binding var value: Double

    var body: some View {
        TextField(placeholder, text: Binding(
            get: { value == 0 ? "" : amountString(value) },
            set: { value = Double($0.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0 }
        ))
        .keyboardType(.decimalPad)
    }
}

// MARK: - 실·바늘 보관함

struct StashView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var tab = Tab.yarn
    @State private var editingYarn: StashYarn?
    @State private var editingNeedle: StashNeedle?

    enum Tab: Hashable { case yarn, needle }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    WobblySegmented(selection: $tab, items: [
                        (Tab.yarn, "실 \(store.stash.yarns.count)"),
                        (Tab.needle, "바늘 \(store.stash.needles.count)"),
                    ])
                    if tab == .yarn { yarnList } else { needleList }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("실·바늘 보관함")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if tab == .yarn { editingYarn = StashYarn() } else { editingNeedle = StashNeedle() }
                    } label: { Label(tab == .yarn ? "실 추가" : "바늘 추가", systemImage: "plus") }
                }
            }
            .sheet(item: $editingYarn) { YarnEditSheet(yarn: $0) }
            .sheet(item: $editingNeedle) { NeedleEditSheet(needle: $0) }
        }
    }

    @ViewBuilder
    private var yarnList: some View {
        if store.stash.yarns.isEmpty {
            EmptyStateView(title: "보관함에 실이 없어요",
                           message: "가지고 있는 실을 넣어 두세요.\n작품에 연결하면 남은 양을 알아서 계산해요.",
                           buttonTitle: "실 추가") { editingYarn = StashYarn() }
                .padding(.top, 60)
        }
        ForEach(store.stash.yarns) { y in
            Button { editingYarn = y } label: { YarnStashCard(yarn: y) }
                .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var needleList: some View {
        if store.stash.needles.isEmpty {
            EmptyStateView(title: "보관함에 바늘이 없어요",
                           message: "가지고 있는 바늘을 넣어 두세요.\n어떤 바늘이 어느 작품에 쓰이는지 보여요.",
                           buttonTitle: "바늘 추가") { editingNeedle = StashNeedle() }
                .padding(.top, 60)
        }
        ForEach(store.stash.needles) { n in
            Button { editingNeedle = n } label: {
                let using = store.projectsUsing(needleID: n.id)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(n.title.isEmpty ? "바늘" : n.title).appFont(.headline)
                        Spacer()
                        Pill(text: using.isEmpty ? "쉬는 중" : "사용 중",
                             fg: using.isEmpty ? Theme.sage : Theme.warnInk,
                             bg: using.isEmpty ? Theme.sageSoft : Theme.warnBg)
                    }
                    if !using.isEmpty {
                        Text(using.map(\.name).joined(separator: ", ")).appFont(.subheadline).foregroundStyle(Theme.muted)
                    }
                    if !n.note.isEmpty { Text(n.note).appFont(.caption).foregroundStyle(Theme.muted) }
                }
                .foregroundStyle(Theme.text)
                .card()
            }
            .buttonStyle(.plain)
        }
    }
}

struct YarnStashCard: View {
    @Environment(Store.self) private var store
    let yarn: StashYarn

    var body: some View {
        let left = store.remaining(yarn)
        let using = store.projectsUsing(yarnID: yarn.id)
        HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(yarn.title.isEmpty ? "실" : yarn.title).appFont(.headline)
                if !yarn.photo.isEmpty {
                    Image(systemName: "camera").font(.system(size: 13)).foregroundStyle(Theme.muted)
                        .accessibilityLabel("사진 있음")
                }
                Spacer()
                Pill(text: left < 0 ? "부족 \(amountString(-left))\(yarn.unit)" : "남은 \(amountString(left))\(yarn.unit)",
                     fg: left < 0 ? Theme.danger : (left == 0 ? Theme.muted : Theme.sage),
                     bg: left < 0 ? Theme.accentSoft : (left == 0 ? Theme.surface2 : Theme.sageSoft))
            }
            Text(["가진 양 \(amountString(yarn.amount))\(yarn.unit)", yarn.weight, yarn.needleText.isEmpty ? "" : "권장 바늘 \(yarn.needleText)"].filter { !$0.isEmpty }.joined(separator: " · "))
                .appFont(.subheadline).foregroundStyle(Theme.muted)
            if !using.isEmpty {
                Text("쓰는 작품: " + using.map { p in
                    let amt = p.yarnLinks.first { $0.yarnID == yarn.id }?.amount ?? 0
                    return "\(p.name) \(amountString(amt))\(yarn.unit)"
                }.joined(separator: ", "))
                .appFont(.subheadline)
            }
            let done = store.projectsDone(yarnID: yarn.id)
            if !done.isEmpty {
                Text("완성한 작품: " + done.map { p in
                    let amt = p.deducted.first { $0.yarnID == yarn.id }?.amount ?? 0
                    return "\(p.name) \(amountString(amt))\(yarn.unit)"
                }.joined(separator: ", "))
                .appFont(.subheadline).foregroundStyle(Theme.muted)
            }
            if left < 0 {
                Text("가진 양보다 \(amountString(-left))\(yarn.unit) 더 필요해요").appFont(.caption).foregroundStyle(Theme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.text)
        .card()
    }
}

// MARK: - 보관함 실·바늘 편집

struct YarnEditSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var yarn: StashYarn
    @State private var confirmDelete = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var newFiles: [String] = []   // 저장 안 하고 닫으면 지울 새 사진
    @State private var viewingPhoto = false
    private let isNew: Bool

    init(yarn: StashYarn) {
        _yarn = State(initialValue: yarn)
        isNew = yarn.name.isEmpty && yarn.amount == 0 && yarn.color.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !yarn.photo.isEmpty {
                        Button { viewingPhoto = true } label: { YarnPhotoLarge(fileName: yarn.photo) }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .accessibilityLabel("실 사진 크게 보기")
                    } else {
                        photoMenu(label: "사진 넣기")
                    }
                } header: {
                    HStack {
                        Text("사진")
                        Spacer()
                        if !yarn.photo.isEmpty {
                            HStack(spacing: 14) {
                                photoMenu(label: "바꾸기", icon: false)
                                Button("삭제", role: .destructive) { yarn.photo = "" }
                                    .foregroundStyle(Theme.danger)
                            }
                            .appFont(.subheadline)
                            .textCase(nil)
                        }
                    }
                }
                Section {
                    TextField("실 이름 (예: 메리노 울)", text: $yarn.name)
                    TextField("색 (예: 그레이)", text: $yarn.color)
                    TextField("굵기 (선택, 예: DK, 합사)", text: $yarn.weight)
                }
                Section {
                    HStack {
                        Text("가진 양")
                        Spacer()
                        DecimalField(placeholder: "0", value: $yarn.amount)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Picker("단위", selection: $yarn.unit) {
                            Text("볼").tag("볼"); Text("g").tag("g"); Text("m").tag("m")
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                } footer: {
                    Text("작품에 연결한 양은 자동으로 빼서 ‘남은 양’으로 보여 줘요.")
                }
                Section {
                    HStack {
                        Text("권장 바늘")
                        Spacer()
                        TextField("예: 4, 3.5~4", text: $yarn.needleSize)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 110)
                        Picker("단위", selection: $yarn.needleUnit) {
                            Text("mm").tag("mm"); Text("호").tag("호")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 96)
                    }
                } footer: {
                    Text(verbatim: "실 라벨에 적힌 바늘 굵기를 mm나 호수로 적어 두세요.")
                }
                Section("메모") { TextField("예: 세일 때 구매, 로트 번호", text: $yarn.note, axis: .vertical) }
                if !isNew {
                    Section { Button("이 실 삭제", role: .destructive) { confirmDelete = true } }
                }
            }
            .navigationTitle(isNew ? "실 추가" : "실 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { newFiles.forEach(Store.removePhotoFile); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        newFiles.filter { $0 != yarn.photo }.forEach(Store.removePhotoFile)
                        store.saveYarn(yarn)
                        dismiss()
                    }
                        .disabled(yarn.name.trimmingCharacters(in: .whitespaces).isEmpty && yarn.color.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("이 실을 보관함에서 지울까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) { store.deleteYarn(yarn.id); dismiss() }
            } message: { Text("작품에 연결된 것도 함께 풀려요.") }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    defer { photoItem = nil }
                    if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) { setPhoto(img) }
                }
            }
            .fullScreenCover(isPresented: $showCamera) { CameraPicker { setPhoto($0) }.ignoresSafeArea() }
            .fullScreenCover(isPresented: $viewingPhoto) { SinglePhotoViewer(fileName: yarn.photo, title: yarn.title) }
        }
        .interactiveDismissDisabled(!newFiles.isEmpty)
    }

    private func photoMenu(label: String, icon: Bool = true) -> some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: { Label("사진 찍기", systemImage: "camera") }
            }
            PhotosPicker(selection: $photoItem, matching: .images) { Label("앨범에서 고르기", systemImage: "photo.on.rectangle") }
        } label: {
            if icon { Label(label, systemImage: "camera") } else { Text(label) }
        }
    }

    private func setPhoto(_ image: UIImage) {
        guard let data = PhotoFiles.jpegData(from: image), let name = try? Store.savePhotoFile(data) else { return }
        newFiles.append(name)
        yarn.photo = name
    }
}

/// 사진 한 장 크게 보기 (확대 가능)
struct SinglePhotoViewer: View {
    let fileName: String
    var title: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            ZoomablePhoto(fileName: fileName)
            HStack {
                Text(title).appFont(.headline).foregroundStyle(.white).lineLimit(1)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17)).frame(width: 44, height: 44)
                        .background(.white.opacity(0.15), in: Circle())
                }
                .foregroundStyle(.white)
                .accessibilityLabel("닫기")
            }
            .padding(.horizontal, 16)
        }
    }
}

struct NeedleEditSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var needle: StashNeedle
    @State private var confirmDelete = false
    private let isNew: Bool

    init(needle: StashNeedle) {
        _needle = State(initialValue: needle)
        isNew = needle.size.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("종류", selection: $needle.kind) {
                        ForEach(["대바늘", "줄바늘", "코바늘", "기타"], id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    TextField("크기 (예: 4.5mm, 80cm)", text: $needle.size)
                }
                Section("메모") { TextField("예: 대나무, 2세트", text: $needle.note, axis: .vertical) }
                if !isNew {
                    Section { Button("이 바늘 삭제", role: .destructive) { confirmDelete = true } }
                }
            }
            .navigationTitle(isNew ? "바늘 추가" : "바늘 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { store.saveNeedle(needle); dismiss() }
                        .disabled(needle.size.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("이 바늘을 보관함에서 지울까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive) { store.deleteNeedle(needle.id); dismiss() }
            }
        }
    }
}

// MARK: - 작품 화면의 재료 칸

struct MaterialsSection: View {
    @Environment(Store.self) private var store
    let project: Project
    var onPick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "재료") {
                Button(action: onPick) { Label("보관함에서 고르기", systemImage: "shippingbox") }
                    .buttonStyle(ChipStyle())
            }
            let links = project.yarnLinks.compactMap { l in store.yarn(l.yarnID).map { (l, $0) } }
            let needles = project.needleIDs.compactMap { store.needle($0) }
            if links.isEmpty && needles.isEmpty {
                HintBox(text: "보관함의 실과 바늘을 이 작품에 연결해 두면, 남은 양을 챙겨 주고, 완성하면 쓴 실을 보관함에서 알아서 빼 줘요.")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(links, id: \.0.yarnID) { link, y in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(y.title).appFont(.body)
                                if project.isDone {
                                    let took = project.deducted.first { $0.yarnID == y.id }?.amount ?? 0
                                    Text(took > 0 ? "완성하면서 보관함에서 \(amountString(took))\(y.unit) 뺐어요" : "보관함에 남은 양이 없어서 빼지 않았어요")
                                        .appFont(.caption)
                                        .foregroundStyle(Theme.muted)
                                } else {
                                    Text(store.remaining(y) < 0 ? "보관함보다 \(amountString(-store.remaining(y)))\(y.unit) 부족해요" : "보관함 남은 \(amountString(store.remaining(y)))\(y.unit)")
                                        .appFont(.caption)
                                        .foregroundStyle(store.remaining(y) < 0 ? Theme.danger : Theme.muted)
                                }
                            }
                            Spacer()
                            Pill(text: "\(amountString(link.amount))\(y.unit)")
                        }
                    }
                    if !needles.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "line.diagonal").foregroundStyle(Theme.accentText)
                            Text(needles.map(\.title).joined(separator: ", ")).appFont(.body)
                        }
                    }
                }
                .foregroundStyle(Theme.text)
                .card()
            }
        }
    }
}

// MARK: - 보관함에서 고르기

struct MaterialPickerSheet: View {
    let projectID: String
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var amounts: [String: Double] = [:]
    @State private var needleIDs: Set<String> = []
    @State private var showStash = false

    init(project: Project) {
        projectID = project.id
        _amounts = State(initialValue: Dictionary(uniqueKeysWithValues: project.yarnLinks.map { ($0.yarnID, $0.amount) }))
        _needleIDs = State(initialValue: Set(project.needleIDs))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if store.stash.yarns.isEmpty {
                        Text("보관함에 실이 없어요.").foregroundStyle(.secondary)
                    }
                    ForEach(store.stash.yarns) { y in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(y.title.isEmpty ? "실" : y.title)
                                Text("가진 \(amountString(y.amount))\(y.unit)").appFont(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            DecimalField(placeholder: "0", value: Binding(
                                get: { amounts[y.id] ?? 0 },
                                set: { amounts[y.id] = $0 }
                            ))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 64)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            Text(y.unit).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("이 작품에 쓸 실")
                } footer: {
                    Text("쓸 양을 적으면 연결되고, 비우면 연결이 풀려요.")
                }
                Section("이 작품에 쓸 바늘") {
                    if store.stash.needles.isEmpty {
                        Text("보관함에 바늘이 없어요.").foregroundStyle(.secondary)
                    }
                    ForEach(store.stash.needles) { n in
                        Toggle(n.title, isOn: Binding(
                            get: { needleIDs.contains(n.id) },
                            set: { if $0 { needleIDs.insert(n.id) } else { needleIDs.remove(n.id) } }
                        ))
                    }
                }
                Section {
                    Button { showStash = true } label: { Label("보관함 열기 (실·바늘 추가)", systemImage: "shippingbox") }
                }
            }
            .navigationTitle("보관함에서 고르기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { apply(); dismiss() }
                }
            }
            .sheet(isPresented: $showStash) { StashView() }
        }
    }

    private func apply() {
        guard let p = store.project(projectID) else { return }
        for y in store.stash.yarns {
            let want = amounts[y.id] ?? 0
            let had = p.yarnLinks.first { $0.yarnID == y.id }?.amount ?? 0
            if want != had { store.linkYarn(projectID, yarnID: y.id, amount: want) }
        }
        for n in store.stash.needles where needleIDs.contains(n.id) != p.needleIDs.contains(n.id) {
            store.toggleNeedle(projectID, needleID: n.id)
        }
    }
}

/// 실 정보 맨 위의 큰 사진
struct YarnPhotoLarge: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Theme.surface2
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "photo").foregroundStyle(Theme.muted)
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .task(id: fileName) { image = PhotoFiles.full(fileName) }
    }
}
