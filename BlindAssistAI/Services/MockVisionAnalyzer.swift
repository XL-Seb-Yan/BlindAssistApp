import Foundation

final class MockVisionAnalyzer {
  private var index = 0

  private let mockResults: [VisionAnalysisResult] = [
    VisionAnalysisResult(
      riskLevel: .low,
      mainObstacle: LocalizedText(
        traditionalChinese: "前方道路較空曠",
        simplifiedChinese: "前方道路较空旷",
        english: "The path ahead appears mostly clear"
      ),
      direction: "forward",
      spokenResponse: LocalizedText(
        traditionalChinese: "前方未發現明顯障礙，可以謹慎直行。",
        simplifiedChinese: "前方未发现明显障碍，可以谨慎直行。",
        english: "No obvious obstacle ahead. You may continue forward carefully."
      )
    ),
    VisionAnalysisResult(
      riskLevel: .medium,
      mainObstacle: LocalizedText(
        traditionalChinese: "前方有行人經過",
        simplifiedChinese: "前方有行人经过",
        english: "A pedestrian may be passing ahead"
      ),
      direction: "slow",
      spokenResponse: LocalizedText(
        traditionalChinese: "前方有人經過，請放慢速度。",
        simplifiedChinese: "前方有人经过，请放慢速度。",
        english: "Someone may be passing ahead. Please slow down."
      )
    ),
    VisionAnalysisResult(
      riskLevel: .medium,
      mainObstacle: LocalizedText(
        traditionalChinese: "右前方可能有椅子或障礙物",
        simplifiedChinese: "右前方可能有椅子或障碍物",
        english: "There may be a chair or obstacle ahead on the right"
      ),
      direction: "left",
      spokenResponse: LocalizedText(
        traditionalChinese: "右前方有障礙物，請向左慢慢繞行。",
        simplifiedChinese: "右前方有障碍物，请向左慢慢绕行。",
        english: "There is an obstacle ahead on the right. Move left slowly."
      )
    ),
    VisionAnalysisResult(
      riskLevel: .high,
      mainObstacle: LocalizedText(
        traditionalChinese: "前方可能有樓梯或明顯高度變化",
        simplifiedChinese: "前方可能有楼梯或明显高度变化",
        english: "There may be stairs or a height change ahead"
      ),
      direction: "stop",
      spokenResponse: LocalizedText(
        traditionalChinese: "前方可能有危險，請先停下確認。",
        simplifiedChinese: "前方可能有危险，请先停下确认。",
        english: "There may be danger ahead. Please stop and check first."
      )
    ),
    VisionAnalysisResult(
      riskLevel: .unknown,
      mainObstacle: LocalizedText(
        traditionalChinese: "畫面不清晰或光線不足",
        simplifiedChinese: "画面不清晰或光线不足",
        english: "The image is unclear or the lighting is too low"
      ),
      direction: "unknown",
      spokenResponse: LocalizedText(
        traditionalChinese: "暫時無法判斷前方情況，請重新拍照。",
        simplifiedChinese: "暂时无法判断前方情况，请重新拍照。",
        english: "I cannot determine the situation ahead. Please take another photo."
      )
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
      mainObstacle: LocalizedText(
        traditionalChinese: "前方近距離有危險障礙物",
        simplifiedChinese: "前方近距离有危险障碍物",
        english: "There is a dangerous obstacle very close ahead"
      ),
      direction: "stop",
      spokenResponse: LocalizedText(
        traditionalChinese: "前方有危險障礙物，請立即停下。",
        simplifiedChinese: "前方有危险障碍物，请立即停下。",
        english: "Dangerous obstacle ahead. Please stop immediately."
      )
    )
  }
}
