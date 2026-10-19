//
//  OpenAIVisionAnalyzer.swift
//  BlindAssistAI
//
//  Created by Jason Huang on 19/10/2026.
//
import UIKit

final class OpenAIVisionAnalyzer: VisionAnalyzing {

    func analyzeImage(
        _ image: UIImage
    ) async throws -> VisionAnalysisResult {

        guard let imageData =
            ImageProcessor.prepareForUpload(image) else {
            throw ImageProcessingError.failed
        }
        if let originalData = image.jpegData(
            compressionQuality: 1.0
        ) {
            print(
                "Original: \(originalData.count / 1024) KB"
            )
        }

        print(
            "Compressed: \(imageData.count / 1024) KB"
        )
        print("Upload size: \(imageData.count) bytes")

        // 下一步：
        // 把 imageData POST 到 Backend

        fatalError("Backend connection not implemented yet")
    }
}


enum ImageProcessingError: Error {
    case failed
}
