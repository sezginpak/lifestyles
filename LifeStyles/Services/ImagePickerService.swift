//
//  ImagePickerService.swift
//  LifeStyles
//
//  Created by Claude on 25.10.2025.
//  Image picking & compression service
//

import SwiftUI
import PhotosUI

/// PHPickerViewController wrapper for SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self = self, let uiImage = image as? UIImage else { return }

                    // Compress image
                    DispatchQueue.main.async {
                        self.parent.imageData = ImageCompressionService.compress(uiImage)
                    }
                }
            }
        }
    }
}

/// Image compression utilities
enum ImageCompressionService {
    /// Maximum image dimension (width or height)
    static let maxDimension: CGFloat = 1920

    /// JPEG compression quality
    static let compressionQuality: CGFloat = 0.7

    /// Thumbnail max dimension
    static let thumbnailMaxDimension: CGFloat = 400

    /// Thumbnail compression quality
    static let thumbnailCompressionQuality: CGFloat = 0.5

    /// Compress image to optimal size
    static func compress(_ image: UIImage) -> Data? {
        // Resize if needed
        let resized = resize(image, maxDimension: maxDimension)

        // Convert to JPEG data
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    /// Create compressed thumbnail
    static func createThumbnail(_ image: UIImage) -> Data? {
        let resized = resize(image, maxDimension: thumbnailMaxDimension)
        return resized.jpegData(compressionQuality: thumbnailCompressionQuality)
    }

    /// Resize image maintaining aspect ratio
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if size.width > size.height {
            // Landscape
            if size.width > maxDimension {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                return image
            }
        } else {
            // Portrait
            if size.height > maxDimension {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            } else {
                return image
            }
        }

        // Render
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Convert Data to UIImage
    static func dataToImage(_ data: Data) -> UIImage? {
        UIImage(data: data)
    }

    /// Convert UIImage to Data
    static func imageToData(_ image: UIImage) -> Data? {
        compress(image)
    }
}

/// SwiftUI View Extension for Image Data
extension View {
    /// Display image from Data
    func imageFromData(_ data: Data?) -> some View {
        Group {
            if let data = data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }
}
