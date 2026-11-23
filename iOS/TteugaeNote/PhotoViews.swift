import SwiftUI
import UIKit
import PhotosUI

// MARK: - 사진 파일 도우미

enum PhotoFiles {
    private static let cache = NSCache<NSString, UIImage>()

    /// 회전을 반영하고 긴 변 2000px로 줄여서 JPEG로
    static func jpegData(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 2000
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        let target = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let img = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return img.jpegData(compressionQuality: 0.85)
    }

    static func thumbnail(_ fileName: String) async -> UIImage? {
        let key = fileName as NSString
        if let c = cache.object(forKey: key) { return c }
        guard let img = UIImage(contentsOfFile: Store.photoURL(fileName).path) else { return nil }
        let thumb = await img.byPreparingThumbnail(ofSize: CGSize(width: 360, height: 360)) ?? img
        cache.setObject(thumb, forKey: key)
        return thumb
    }

    static func full(_ fileName: String) -> UIImage? {
        UIImage(contentsOfFile: Store.photoURL(fileName).path)
    }
}

/// 정사각형으로 잘라 보여 주는 작은 사진
struct PhotoThumb: View {
    let fileName: String
    var size: CGFloat = 110
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
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .task(id: fileName) { image = await PhotoFiles.thumbnail(fileName) }
    }
}

// MARK: - 작품 화면의 사진 칸

struct PhotosSection: View {
    let project: Project
    @Environment(Store.self) private var store
    @Environment(ToastCenter.self) private var toast
    @State private var showPicker = false
    @State private var showCamera = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var viewing: ViewerTarget?

    struct ViewerTarget: Identifiable { let id: String }

    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "사진") {
                Menu {
                    if cameraAvailable {
                        Button { showCamera = true } label: { Label("사진 찍기", systemImage: "camera") }
                    }
                    Button { showPicker = true } label: { Label("앨범에서 고르기", systemImage: "photo.on.rectangle") }
                } label: {
                    Label("추가", systemImage: "plus")
                }
                .buttonStyle(ChipStyle())
            }
            if project.photos.isEmpty {
                HintBox(text: "뜨는 중간중간, 그리고 완성했을 때 사진을 남겨 두세요. 찍은 단도 함께 기록돼요.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(project.photos.reversed()) { ph in
                            Button { viewing = ViewerTarget(id: ph.id) } label: {
                                PhotoThumb(fileName: ph.fileName)
                                    .overlay(alignment: .bottomLeading) {
                                        Text("\(ph.row)단")
                                            .font(.app(.caption))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .background(.black.opacity(0.45), in: Capsule())
                                            .foregroundStyle(.white)
                                            .padding(6)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(ph.row)단 사진")
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItems, maxSelectionCount: 10, matching: .images)
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                var added = 0
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data), save(img) { added += 1 }
                }
                pickerItems = []
                toast.show(added > 0 ? "사진 \(added)장을 붙였어요" : "사진을 불러오지 못했어요")
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { img in
                if save(img) { toast.show("사진을 붙였어요") }
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $viewing) { t in
            PhotoViewer(projectID: project.id, startID: t.id)
        }
    }

    private func save(_ img: UIImage) -> Bool {
        guard let data = PhotoFiles.jpegData(from: img) else { return false }
        return (try? store.addPhoto(project.id, jpegData: data)) != nil
    }
}

// MARK: - 크게 보기

struct PhotoViewer: View {
    let projectID: String
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var current: String
    @State private var caption = ""
    @State private var confirmDelete = false
    @FocusState private var editing: Bool

    init(projectID: String, startID: String) {
        self.projectID = projectID
        _current = State(initialValue: startID)
    }

    private var photos: [ProjectPhoto] { Array((store.project(projectID)?.photos ?? []).reversed()) }
    private var photo: ProjectPhoto? { photos.first { $0.id == current } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $current) {
                ForEach(photos) { ph in
                    ZoomablePhoto(fileName: ph.fileName).tag(ph.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .automatic : .never))
            .ignoresSafeArea()
            .onTapGesture { editing = false }

            VStack {
                HStack {
                    circleButton("xmark", label: "닫기") { saveCaption(); dismiss() }
                    Spacer()
                    if let photo { ShareLink(item: Image(uiImage: PhotoFiles.full(photo.fileName) ?? UIImage()), preview: SharePreview("뜨개 사진")) {
                        Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44)
                    }
                    .foregroundStyle(.white)
                    .background(.white.opacity(0.15), in: Circle())
                    .accessibilityLabel("공유")
                    }
                    circleButton("trash", label: "사진 삭제") { confirmDelete = true }
                }
                .padding(.horizontal, 16)
                Spacer()
                if let photo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(photo.createdDate.formatted(.dateTime.year().month().day())) · \(photo.row)단")
                            .font(.app(.subheadline))
                            .foregroundStyle(.white.opacity(0.75))
                        TextField("", text: $caption, prompt: Text("한 줄 메모 (예: 앞판 완성!)").foregroundStyle(.white.opacity(0.5)))
                            .font(.app(.body))
                            .foregroundStyle(.white)
                            .focused($editing)
                            .submitLabel(.done)
                            .onSubmit(saveCaption)
                            .padding(12)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(16)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
                }
            }
        }
        .onAppear { caption = photo?.caption ?? "" }
        .onChange(of: current) { old, _ in
            store.setPhotoCaption(projectID, photoID: old, caption)
            caption = photo?.caption ?? ""
        }
        .onChange(of: editing) { _, now in if !now { saveCaption() } }
        .confirmationDialog("이 사진을 지울까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("삭제", role: .destructive) { deleteCurrent() }
            Button("취소", role: .cancel) {}
        }
        .preferredColorScheme(.dark)
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).frame(width: 44, height: 44)
        }
        .foregroundStyle(.white)
        .background(.white.opacity(0.15), in: Circle())
        .accessibilityLabel(label)
    }

    private func saveCaption() {
        store.setPhotoCaption(projectID, photoID: current, caption)
    }

    private func deleteCurrent() {
        let list = photos
        guard let i = list.firstIndex(where: { $0.id == current }) else { return }
        let next = list.count > 1 ? list[i + 1 < list.count ? i + 1 : i - 1].id : nil
        store.deletePhoto(projectID, photoID: current)
        if let next { current = next; caption = photo?.caption ?? "" } else { dismiss() }
    }
}

/// 두 손가락으로 확대, 두 번 탭하면 원래대로
struct ZoomablePhoto: View {
    let fileName: String
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var base: CGFloat = 1

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(MagnifyGesture()
                        .onChanged { scale = max(1, min(4, base * $0.magnification)) }
                        .onEnded { _ in base = scale })
                    .onTapGesture(count: 2) { withAnimation { scale = 1; base = 1 } }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo").font(.largeTitle)
                    Text("사진 파일이 없어요").font(.app(.body))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: fileName) { image = PhotoFiles.full(fileName) }
    }
}

// MARK: - 카메라

struct CameraPicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let c = UIImagePickerController()
        c.sourceType = .camera
        c.delegate = context.coordinator
        return c
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onPick(img) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
