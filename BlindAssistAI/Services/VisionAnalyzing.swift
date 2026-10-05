//
//  VisionAnalyzing.swift
//  BlindAssistAI
//
//  Created by Jason Huang on 5/10/2026.
//
import UIKit

protocol VisionAnalyzing {
    func analyzeImage(_ image: UIImage) async throws -> VisionAnalysisResult
    }
