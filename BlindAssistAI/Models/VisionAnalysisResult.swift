import Foundation

struct VisionAnalysisResult {
  let riskLevel: RiskLevel
  let mainObstacle: LocalizedText
  let direction: String
  let spokenResponse: LocalizedText
}
