import Foundation

enum AppLanguage: Equatable {
  case traditionalChinese
  case simplifiedChinese
  case english

  var speechCode: String {
    switch self {
    case .traditionalChinese:
      return "zh-HK"
    case .simplifiedChinese:
      return "zh-CN"
    case .english:
      return "en-US"
    }
  }

  var next: AppLanguage {
    switch self {
    case .traditionalChinese:
      return .simplifiedChinese
    case .simplifiedChinese:
      return .english
    case .english:
      return .traditionalChinese
    }
  }

  var toggleTitle: String {
    next.displayName
  }

  var toggleAccessibilityLabel: String {
    switch next {
    case .traditionalChinese:
      return "切換語言為繁體中文"
    case .simplifiedChinese:
      return "切换语言为简体中文"
    case .english:
      return "Switch language to English"
    }
  }

  var displayName: String {
    switch self {
    case .traditionalChinese:
      return "繁體"
    case .simplifiedChinese:
      return "简体"
    case .english:
      return "English"
    }
  }

  var isChinese: Bool {
    self != .english
  }
}
