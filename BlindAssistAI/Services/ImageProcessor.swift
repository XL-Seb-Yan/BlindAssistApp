//
//  ImageProcessor.swift
//  BlindAssistAI
//
//  Created by Jason Huang on 19/10/2026.
//
import UIKit

struct ImageProcessor {

    static func prepareForUpload(
        _ image: UIImage,
        maxDimension: CGFloat = 1024,
        compressionQuality: CGFloat = 0.6
    ) -> Data? {

        let resizedImage = resize(
            image,
            maxDimension: maxDimension
        )

        return resizedImage.jpegData(
            compressionQuality: compressionQuality
        )
    }


    private static func resize(
        _ image: UIImage,
        maxDimension: CGFloat
    ) -> UIImage {

        let originalSize = image.size

        let scale = min(
            maxDimension / originalSize.width,
            maxDimension / originalSize.height,
            1.0
        )

        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(
            size: newSize
        )

        return renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: newSize
                )
            )
        }
    }
}
