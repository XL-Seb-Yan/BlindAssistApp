import Foundation

enum RiskLevel {
  case low
  case medium
  case high
  case unknown

  func displayText(for language: AppLanguage) -> String {
    switch (self, language) {
    case (.low, .traditionalChinese):
      return "低風險"
    case (.low, .simplifiedChinese):
      return "低风险"
    case (.low, .english):
      return "Low risk"
    case (.medium, .traditionalChinese):
      return "中風險"
    case (.medium, .simplifiedChinese):
      return "中风险"
    case (.medium, .english):
      return "Medium risk"
    case (.high, .traditionalChinese):
      return "高風險"
    case (.high, .simplifiedChinese):
      return "高风险"
    case (.high, .english):
      return "High risk"
    case (.unknown, .traditionalChinese):
      return "無法判斷"
    case (.unknown, .simplifiedChinese):
      return "无法判断"
    case (.unknown, .english):
      return "Unknown"
    }
  }
}
