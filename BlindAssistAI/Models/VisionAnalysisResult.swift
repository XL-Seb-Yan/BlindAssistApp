import Foundation

struct VisionAnalysisResult: Codable {
  let riskLevel: RiskLevel
  let mainObstacle: LocalizedText
  let direction: String
  let spokenResponse: LocalizedText
}
