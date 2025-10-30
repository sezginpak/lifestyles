//
//  ImageVideoPicker.swift
//  LifeStyles
//
//  Created by Claude on 26.10.2025.
//  Camera/Video Picker Wrapper
//

import SwiftUI
import UIKit
import AVFoundation
import PhotosUI

// MARK: - Media Type

enum MediaType {
    case photo
    case video
}

// MARK: - Media Item

struct MediaItem: Identifiable {
    let id = UUID()
    let type: MediaType
    let data: Data
    let thumbnailData: Data?

    init(type: MediaType, data: Data, thumbnailData: Data? = nil) {
        self.type = type
        self.data = data
        self.thumbnailData = thumbnailData
    }
}

// MARK: - Image/Video Picker

struct ImageVideoPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedMedia: [MediaItem]

    var sourceType: UIImagePickerController.SourceType = .camera
    var mediaTypes: [String] = ["public.image", "public.movie"] // UTI for both photo and video

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 60 // 60 seconds max
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImageVideoPicker

        init(_ parent: ImageVideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

            if let mediaType = info[.mediaType] as? String {

                if mediaType == "public.image" {
                    // Handle photo
                    if let image = info[.originalImage] as? UIImage {
                        // Resize and compress
                        let resized = image.resizeToFit(maxSize: CGSize(width: 1920, height: 1080))
                        let thumbnail = image.resizeToFit(maxSize: CGSize(width: 300, height: 300))

                        if let imageData = resized.jpegData(compressionQuality: 0.8),
                           let thumbnailData = thumbnail.jpegData(compressionQuality: 0.6) {

                            let mediaItem = MediaItem(
                                type: .photo,
                                data: imageData,
                                thumbnailData: thumbnailData
                            )
                            parent.selectedMedia.append(mediaItem)
                        }
                    }

                } else if mediaType == "public.movie" {
                    // Handle video
                    if let videoURL = info[.mediaURL] as? URL {
                        do {
                            let videoData = try Data(contentsOf: videoURL)

                            // Generate thumbnail
                            let thumbnail = VideoThumbnailGenerator.generateThumbnail(for: videoURL)
                            let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.7)

                            let mediaItem = MediaItem(
                                type: .video,
                                data: videoData,
                                thumbnailData: thumbnailData
                            )
                            parent.selectedMedia.append(mediaItem)

                        } catch {
                            print("❌ Failed to load video: \(error)")
                        }
                    }
                }
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Video Thumbnail Generator

struct VideoThumbnailGenerator {
    static func generateThumbnail(for url: URL, at time: CMTime = CMTime(seconds: 1, preferredTimescale: 60)) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 300)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Failed to generate thumbnail: \(error)")
            return nil
        }
    }
}
