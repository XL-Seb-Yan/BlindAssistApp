import Foundation

struct LocalizedText {
  let traditionalChinese: String
  let simplifiedChinese: String
  let english: String

  init(traditionalChinese: String, simplifiedChinese: String, english: String) {
    self.traditionalChinese = traditionalChinese
    self.simplifiedChinese = simplifiedChinese
    self.english = english
  }

  init(chinese: String, english: String) {
    self.traditionalChinese = chinese
    self.simplifiedChinese = chinese
    self.english = english
  }

  func value(for language: AppLanguage) -> String {
    switch language {
    case .traditionalChinese:
      return traditionalChinese
    case .simplifiedChinese:
      return simplifiedChinese
    case .english:
      return english
    }
  }
}
