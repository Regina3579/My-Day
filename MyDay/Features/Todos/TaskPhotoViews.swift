import AVFoundation
import SwiftUI
import UIKit

/// Camera availability and permission.
@MainActor
enum CameraAccess {
    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    /// Shows the system prompt the first time; returns whether the camera may be used.
    static func request() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
}

/// The system camera, for taking a photo of what a to-do is about.
struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, dismiss: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onPick: (UIImage) -> Void
        private let dismiss: () -> Void

        init(onPick: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onPick = onPick
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onPick(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

/// A to-do's photo, full screen. Pinch or double-tap to zoom.
struct PhotoViewer: View {
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale * pinch)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        MagnifyGesture()
                            .updating($pinch) { value, state, _ in state = value.magnification }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    scale = min(max(scale * value.magnification, 1), 4)
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = scale > 1 ? 1 : 2.5
                        }
                    }
                    .accessibilityLabel("Task photo")
            } else {
                Text("This photo can't be shown.")
                    .font(.rounded(.body, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.2)))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .padding(.trailing, 12)
            .accessibilityLabel("Close photo")
        }
    }
}

/// Take, choose, view, replace or remove the photo in the task sheet.
struct TaskPhotoPanel: View {
    let image: UIImage?
    let isLoading: Bool
    let onTake: () -> Void
    let onChoose: () -> Void
    let onView: () -> Void
    let onRemove: () -> Void

    var body: some View {
        if isLoading {
            ProgressView("Getting your photo…")
                .font(.rounded(.subheadline, weight: .semibold))
                .tint(Palette.hotPink)
                .frame(maxWidth: .infinity, minHeight: 110)
        } else if let image {
            HStack(alignment: .center, spacing: 14) {
                Button(action: onView) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 3)
                        )
                        .shadow(color: Palette.hotPink.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel("Photo")
                .accessibilityHint("Shows the photo full size")

                VStack(alignment: .leading, spacing: 8) {
                    PhotoActionButton(title: "View", symbol: "arrow.up.left.and.arrow.down.right", action: onView)
                    Menu {
                        if CameraAccess.isAvailable {
                            Button("Take Photo", systemImage: "camera", action: onTake)
                        }
                        Button("Choose from Library", systemImage: "photo.on.rectangle", action: onChoose)
                    } label: {
                        PhotoActionLabel(title: "Replace", symbol: "arrow.triangle.2.circlepath")
                    }
                    PhotoActionButton(title: "Remove", symbol: "trash", isDestructive: true, action: onRemove)
                }
            }
        } else {
            HStack(spacing: 10) {
                if CameraAccess.isAvailable {
                    PhotoSourceButton(emoji: "📸", title: "Take Photo", action: onTake)
                }
                PhotoSourceButton(emoji: "🖼️", title: "Choose Photo", action: onChoose)
            }
        }
    }
}

private struct PhotoSourceButton: View {
    let emoji: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 28))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.rounded(.subheadline, weight: .bold))
                    .foregroundStyle(Palette.berry)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: 0xFFF1F7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Palette.bubblegum.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScaleStyle())
    }
}

private struct PhotoActionButton: View {
    let title: String
    let symbol: String
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            PhotoActionLabel(title: title, symbol: symbol, isDestructive: isDestructive)
        }
        .buttonStyle(PressScaleStyle())
    }
}

private struct PhotoActionLabel: View {
    let title: String
    let symbol: String
    var isDestructive = false

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.rounded(.subheadline, weight: .bold))
            .foregroundStyle(isDestructive ? Color(hex: 0xD7263D) : Palette.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().strokeBorder(Palette.bubblegum.opacity(0.3), lineWidth: 1))
            .contentShape(Capsule())
    }
}
