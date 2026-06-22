import Foundation

final class MockVisionAnalyzer {
  private var index = 0

  private let mockResults: [VisionAnalysisResult] = [
    VisionAnalysisResult(
      riskLevel: .low,
      mainObstacle: "前方道路较空旷",
      direction: "forward",
      spokenResponse: "前方安全，可以继续直行。"
    ),
    VisionAnalysisResult(
      riskLevel: .medium,
      mainObstacle: "前方有行人经过",
      direction: "slow",
      spokenResponse: "前方有人经过，请放慢速度。"
    ),
    VisionAnalysisResult(
      riskLevel: .medium,
      mainObstacle: "右前方可能有椅子或障碍物",
      direction: "left",
      spokenResponse: "右前方有障碍物，请向左慢慢绕行。"
    ),
    VisionAnalysisResult(
      riskLevel: .high,
      mainObstacle: "前方可能有楼梯或明显高度变化",
      direction: "stop",
      spokenResponse: "前方可能有危险，请先停下确认。"
    ),
    VisionAnalysisResult(
      riskLevel: .unknown,
      mainObstacle: "画面不清晰或光线不足",
      direction: "unknown",
      spokenResponse: "暂时无法判断前方情况，请重新拍照。"
    )
  ]

  func analyzeImage() -> VisionAnalysisResult {
    let result = mockResults[index]
    index = (index + 1) % mockResults.count
    return result
  }

  func highRiskScene() -> VisionAnalysisResult {
    return VisionAnalysisResult(
      riskLevel: .high,
      mainObstacle: "前方近距离有危险障碍物",
      direction: "stop",
      spokenResponse: "前方有危险障碍物，请立即停下。"
    )
  }
}
