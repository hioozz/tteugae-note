import SwiftUI

@main
struct TteugaeNoteApp: App {
    @State private var store = Store()
    @State private var toast = ToastCenter()

    init() {
        AppFont.register()
        AppFont.configureUIKit()
    }

    var body: some Scene {
        WindowGroup {
            ProjectListView()
                .environment(store)
                .environment(toast)
                .font(.app(.body))
                .tint(Theme.accentText) // 글자·토글에 쓰이는 색은 읽히도록 진한 장미색
                .overlay(alignment: .bottom) {
                    if let message = toast.message {
                        ToastView(message: message)
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .allowsHitTesting(false)
                    }
                }
                .animation(.spring(duration: 0.3), value: toast.message)
        }
    }
}
