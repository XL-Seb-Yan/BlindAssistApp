//
//  OpenAIVisionAnalyzer.swift
//  BlindAssistAI
//
//  Created by Jason Huang on 19/10/2026.
//
import Foundation
import UIKit

final class OpenAIVisionAnalyzer: VisionAnalyzing {

    // Replace with your Mac's local IP address
    private let backendURL =
        "http://127.0.0.1:8000/analyze"

    func analyzeImage(
        _ image: UIImage
    ) async throws -> VisionAnalysisResult {

        // 1. Compress the image
        guard let imageData =
            ImageProcessor.prepareForUpload(image) else {
            throw ImageProcessingError.failed
        }

        print("Image compressed: \(imageData.count / 1024) KB")

        // 2. Prepare HTTP request
        guard let url = URL(string: backendURL) else {
            throw NetworkError.invalidURL
        }

        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = createMultipartBody(
            imageData: imageData,
            boundary: boundary
        )

        // 3. Send image to Backend
        print("Sending image to Backend...")

        let (data, response) =
            try await URLSession.shared.data(for: request)

        guard let httpResponse =
            response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        print("HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            print(
                "Backend error:",
                String(data: data, encoding: .utf8) ?? ""
            )
            throw NetworkError.serverError
        }

        // 4. Decode JSON
        let result = try JSONDecoder().decode(
            VisionAnalysisResult.self,
            from: data
        )

        print("AI result received:", result.riskLevel)
        print("Direction:", result.direction)

        return result
    }

    private func createMultipartBody(
        imageData: Data,
        boundary: String
    ) -> Data {

        var body = Data()

        func append(_ text: String) {
            body.append(Data(text.utf8))
        }

        append("--\(boundary)\r\n")
        append(
            "Content-Disposition: form-data; " +
            "name=\"image\"; filename=\"photo.jpg\"\r\n"
        )
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n--\(boundary)--\r\n")

        return body
    }
}

enum ImageProcessingError: Error {
    case failed
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case serverError
}
