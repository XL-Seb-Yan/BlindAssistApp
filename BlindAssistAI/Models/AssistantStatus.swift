import Foundation

enum AssistantStatus {
  case idle
  case ready
  case analyzing
  case completed
  case paused

  func displayText(for language: AppLanguage) -> String {
    switch (self, language) {
    case (.idle, .traditionalChinese):
      return "未開始"
    case (.idle, .simplifiedChinese):
      return "未开始"
    case (.idle, .english):
      return "Not started"
    case (.ready, .traditionalChinese):
      return "準備拍照"
    case (.ready, .simplifiedChinese):
      return "准备拍照"
    case (.ready, .english):
      return "Ready to scan"
    case (.analyzing, .traditionalChinese):
      return "正在分析"
    case (.analyzing, .simplifiedChinese):
      return "正在分析"
    case (.analyzing, .english):
      return "Analyzing"
    case (.completed, .traditionalChinese):
      return "分析完成"
    case (.completed, .simplifiedChinese):
      return "分析完成"
    case (.completed, .english):
      return "Analysis complete"
    case (.paused, .traditionalChinese):
      return "已暫停"
    case (.paused, .simplifiedChinese):
      return "已暂停"
    case (.paused, .english):
      return "Paused"
    }
  }
}
