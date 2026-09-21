import Combine
import Foundation
import SwiftUI
import UIKit

final class AssistantViewModel: ObservableObject {
  @Published var language: AppLanguage = .simplifiedChinese
  @Published var status: AssistantStatus = .idle

  @Published var latestResult = VisionAnalysisResult(
    riskLevel: .unknown,
    mainObstacle: LocalizedText(
      traditionalChinese: "尚未開始識別",
      simplifiedChinese: "尚未开始识别",
      english: "Scanning has not started"
    ),
    direction: "unknown",
    spokenResponse: LocalizedText(
      traditionalChinese: "歡迎使用助盲環境感知助手。請點擊拍照分析。",
      simplifiedChinese: "欢迎使用助盲环境感知助手。请点击拍照分析。",
      english: "Welcome to BlindAssist AI. Tap scan to analyze your surroundings."
    )
  )

  @Published var capturedImage: UIImage?
  @Published var showCamera = false
  @Published var showAlert = false
  @Published var alertMessage = ""

  private let speechManager = SpeechManager()
  private let hapticManager = HapticManager()
  private let analyzer = MockVisionAnalyzer()

  func toggleLanguage() {
    language = language.next
    speechManager.speak(text.languageChanged, language: language.speechCode)
  }

  func openCamera() {
    status = .ready

    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      alertMessage = text.cameraUnavailableAlert
      showAlert = true
      speechManager.speak(text.cameraUnavailableSpeech, language: language.speechCode)
      return
    }

    speechManager.speak(text.cameraPrompt, language: language.speechCode)
    showCamera = true
  }

  func handleCapturedImage(_ image: UIImage) {
    capturedImage = image
    analyzeCapturedImage()
  }

  func analyzeCapturedImage() {
    status = .analyzing
    speechManager.speak(text.analyzingSpeech, language: language.speechCode)

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      let result = self.analyzer.analyzeImage()
      self.latestResult = result
      self.status = .completed
      self.handleResultFeedback(result)
    }
  }

  func simulateHighRisk() {
    let result = analyzer.highRiskScene()
    latestResult = result
    status = .completed
    handleResultFeedback(result)
  }

  func pause() {
    status = .paused
    hapticManager.lightTap()
    speechManager.speak(text.pausedSpeech, language: language.speechCode)
  }

  func emergencyHelp() {
    hapticManager.error()
    speechManager.speak(text.emergencyHelpSpeech, language: language.speechCode)
  }

  private func handleResultFeedback(_ result: VisionAnalysisResult) {
    switch result.riskLevel {
    case .low:
      hapticManager.lightTap()
    case .medium:
      hapticManager.warning()
    case .high:
      hapticManager.error()
    case .unknown:
      hapticManager.warning()
    }

    speechManager.speak(result.spokenResponse.value(for: language), language: language.speechCode)
  }

  func directionText(_ direction: String) -> String {
    switch (direction, language) {
    case ("left", .traditionalChinese):
      return "向左繞行"
    case ("left", .simplifiedChinese):
      return "向左绕行"
    case ("left", .english):
      return "Move left"
    case ("right", .traditionalChinese):
      return "向右繞行"
    case ("right", .simplifiedChinese):
      return "向右绕行"
    case ("right", .english):
      return "Move right"
    case ("forward", .traditionalChinese):
      return "謹慎直行"
    case ("forward", .simplifiedChinese):
      return "谨慎直行"
    case ("forward", .english):
      return "Continue carefully"
    case ("stop", .traditionalChinese):
      return "立即停下"
    case ("stop", .simplifiedChinese):
      return "立即停下"
    case ("stop", .english):
      return "Stop immediately"
    case ("slow", .traditionalChinese):
      return "放慢速度"
    case ("slow", .simplifiedChinese):
      return "放慢速度"
    case ("slow", .english):
      return "Slow down"
    case (_, .traditionalChinese):
      return "無法判斷"
    case (_, .simplifiedChinese):
      return "无法判断"
    case (_, .english):
      return "Unknown"
    }
  }

  var statusText: String {
    status.displayText(for: language)
  }

  var spokenResponseText: String {
    latestResult.spokenResponse.value(for: language)
  }

  var mainObstacleText: String {
    latestResult.mainObstacle.value(for: language)
  }

  var riskLevelText: String {
    latestResult.riskLevel.displayText(for: language)
  }

  var text: AppText {
    AppText(language: language)
  }

  var statusColor: Color {
    switch status {
    case .idle:
      return .gray
    case .ready:
      return .blue
    case .analyzing:
      return .orange
    case .completed:
      return .green
    case .paused:
      return .yellow
    }
  }

  var resultBackgroundColor: Color {
    switch latestResult.riskLevel {
    case .low:
      return Color.green.opacity(0.22)
    case .medium:
      return Color.orange.opacity(0.25)
    case .high:
      return Color.red.opacity(0.28)
    case .unknown:
      return Color.gray.opacity(0.22)
    }
  }
}

struct AppText {
  let language: AppLanguage

  var alertTitle: String {
    switch language {
    case .traditionalChinese:
      return "提示"
    case .simplifiedChinese:
      return "提示"
    case .english:
      return "Notice"
    }
  }

  var languageChanged: String {
    switch language {
    case .traditionalChinese:
      return "已切換為繁體中文。"
    case .simplifiedChinese:
      return "已切换为简体中文。"
    case .english:
      return "Language switched to English."
    }
  }

  var headerTitle: String {
    switch language {
    case .traditionalChinese:
      return "助盲環境感知助手"
    case .simplifiedChinese:
      return "助盲环境感知助手"
    case .english:
      return "Blind Environment Assistant"
    }
  }

  var headerSubtitle: String {
    localized(
      traditional: "拍攝前方環境，並用 AI 模擬分析障礙物與風險。",
      simplified: "拍摄前方环境，并用 AI 模拟分析障碍物与风险。",
      english: "Capture the area ahead and simulate AI analysis of obstacles and risk."
    )
  }

  var headerAccessibilityLabel: String {
    localized(
      traditional: "助盲環境感知助手，拍攝前方環境，並用人工智能模擬分析障礙物與風險。",
      simplified: "助盲环境感知助手，拍摄前方环境，并用人工智能模拟分析障碍物与风险。",
      english: "Blind environment assistant. Capture the area ahead and simulate artificial intelligence analysis of obstacles and risk."
    )
  }

  var cameraSectionTitle: String {
    localized(traditional: "目前拍攝畫面", simplified: "当前拍摄画面", english: "Current Photo")
  }

  var noPhotoText: String {
    localized(traditional: "尚未拍攝照片", simplified: "尚未拍摄照片", english: "No photo yet")
  }

  var photoCapturedAccessibilityLabel: String {
    localized(traditional: "已經拍攝一張照片", simplified: "已经拍摄一张照片", english: "One photo has been captured")
  }

  var currentStatusTitle: String {
    localized(traditional: "目前狀態", simplified: "当前状态", english: "Current Status")
  }

  var aiTipTitle: String {
    localized(traditional: "AI 提示", simplified: "AI 提示", english: "AI Guidance")
  }

  var riskLevelTitle: String {
    localized(traditional: "風險等級", simplified: "风险等级", english: "Risk Level")
  }

  var mainSituationTitle: String {
    localized(traditional: "主要情況", simplified: "主要情况", english: "Main Situation")
  }

  var suggestedDirectionTitle: String {
    localized(traditional: "建議方向", simplified: "建议方向", english: "Suggested Direction")
  }

  var scanButtonTitle: String {
    localized(traditional: "拍照分析", simplified: "拍照分析", english: "Scan")
  }

  var scanButtonAccessibility: String {
    localized(
      traditional: "打開攝像頭，拍攝前方環境並分析",
      simplified: "打开摄像头，拍摄前方环境并分析",
      english: "Open the camera, capture the area ahead, and analyze it"
    )
  }

  var retakeButtonTitle: String {
    localized(traditional: "重新拍照", simplified: "重新拍照", english: "Retake Photo")
  }

  var retakeButtonAccessibility: String {
    localized(traditional: "重新拍攝前方環境", simplified: "重新拍摄前方环境", english: "Retake a photo of the area ahead")
  }

  var pauseButtonTitle: String {
    localized(traditional: "暫停識別", simplified: "暂停识别", english: "Pause")
  }

  var pauseButtonAccessibility: String {
    localized(traditional: "暫停識別", simplified: "暂停识别", english: "Pause recognition")
  }

  var simulateHighRiskButtonTitle: String {
    localized(traditional: "模擬高風險", simplified: "模拟高风险", english: "Simulate High Risk")
  }

  var simulateHighRiskButtonAccessibility: String {
    localized(traditional: "模擬高風險場景", simplified: "模拟高风险场景", english: "Simulate a high-risk scene")
  }

  var emergencyHelpButtonTitle: String {
    localized(traditional: "緊急求助", simplified: "紧急求助", english: "Emergency Help")
  }

  var emergencyHelpButtonAccessibility: String {
    localized(traditional: "緊急求助按鈕", simplified: "紧急求助按钮", english: "Emergency help button")
  }

  var safetyTitle: String {
    localized(traditional: "安全提示", simplified: "安全提示", english: "Safety Notice")
  }

  var safetyText: String {
    localized(
      traditional: "本 App 目前是學習與演示原型，只能作為環境感知輔助工具，不能替代導盲杖、導盲犬或真人協助。目前版本已加入真實拍照功能，但 AI 分析仍為模擬結果。",
      simplified: "本 App 目前是学习与演示原型，只能作为环境感知辅助工具，不能替代导盲杖、导盲犬或真人协助。当前版本已加入真实拍照功能，但 AI 分析仍为模拟结果。",
      english: "This app is currently a learning and demo prototype. It is only an environmental awareness aid and cannot replace a white cane, guide dog, or human assistance. This version supports real photo capture, but AI analysis is still simulated."
    )
  }

  var cameraUnavailableAlert: String {
    localized(
      traditional: "目前設備無法使用攝像頭。請使用真實 iPhone 測試，Simulator 可能無法打開相機。",
      simplified: "当前设备无法使用摄像头。请使用真实 iPhone 测试，Simulator 可能无法打开相机。",
      english: "The camera is not available on this device. Please test on a real iPhone. The simulator may not open the camera."
    )
  }

  var cameraUnavailableSpeech: String {
    localized(
      traditional: "目前設備無法使用攝像頭。請使用真實 iPhone 測試。",
      simplified: "当前设备无法使用摄像头。请使用真实 iPhone 测试。",
      english: "The camera is not available on this device. Please test on a real iPhone."
    )
  }

  var cameraPrompt: String {
    localized(
      traditional: "請將手機對準前方，然後拍照。",
      simplified: "请将手机对准前方，然后拍照。",
      english: "Point the phone forward, then take a photo."
    )
  }

  var analyzingSpeech: String {
    localized(traditional: "正在分析前方環境。", simplified: "正在分析前方环境。", english: "Analyzing the area ahead.")
  }

  var pausedSpeech: String {
    localized(traditional: "已暫停識別。", simplified: "已暂停识别。", english: "Recognition paused.")
  }

  var emergencyHelpSpeech: String {
    localized(
      traditional: "緊急求助功能將在後續版本加入。請先聯絡身邊的人。",
      simplified: "紧急求助功能将在后续版本加入。请先联系身边的人。",
      english: "Emergency help will be added in a later version. Please contact someone nearby first."
    )
  }

  func statusAccessibilityLabel(statusText: String) -> String {
    localized(
      traditional: "目前狀態，\(statusText)",
      simplified: "当前状态，\(statusText)",
      english: "Current status, \(statusText)"
    )
  }

  func resultAccessibilityLabel(response: String, riskLevel: String, obstacle: String) -> String {
    localized(
      traditional: "AI 提示，\(response)。風險等級，\(riskLevel)。主要情況，\(obstacle)。",
      simplified: "AI 提示，\(response)。风险等级，\(riskLevel)。主要情况，\(obstacle)。",
      english: "AI guidance, \(response). Risk level, \(riskLevel). Main situation, \(obstacle)."
    )
  }

  private func localized(traditional: String, simplified: String, english: String) -> String {
    switch language {
    case .traditionalChinese:
      return traditional
    case .simplifiedChinese:
      return simplified
    case .english:
      return english
    }
  }
}
