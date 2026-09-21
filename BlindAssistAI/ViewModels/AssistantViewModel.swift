import Combine
import Foundation
import SwiftUI
import UIKit

final class AssistantViewModel: ObservableObject {
  @Published var status: AssistantStatus = .idle

  @Published var latestResult = VisionAnalysisResult(
    riskLevel: .unknown,
    mainObstacle: "尚未开始识别",
    direction: "unknown",
    spokenResponse: "欢迎使用助盲环境感知助手。请点击拍照分析。"
  )

  @Published var capturedImage: UIImage?
  @Published var showCamera = false
  @Published var showAlert = false
  @Published var alertMessage = ""

  private let speechManager = SpeechManager()
  private let hapticManager = HapticManager()
  private let analyzer = MockVisionAnalyzer()

  func openCamera() {
    status = .ready

    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      alertMessage = "当前设备无法使用摄像头。请使用真实 iPhone 测试，Simulator 可能无法打开相机。"
      showAlert = true
      speechManager.speak("当前设备无法使用摄像头。请使用真实 iPhone 测试。")
      return
    }

    speechManager.speak("请将手机对准前方，然后拍照。")
    showCamera = true
  }

  func handleCapturedImage(_ image: UIImage) {
    capturedImage = image
    analyzeCapturedImage()
  }

  func analyzeCapturedImage() {
    status = .analyzing
    speechManager.speak("正在分析前方环境。")

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
    speechManager.speak("已暂停识别。")
  }

  func emergencyHelp() {
    hapticManager.error()
    speechManager.speak("紧急求助功能将在后续版本加入。请先联系身边的人。")
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

    speechManager.speak(result.spokenResponse)
  }

  func directionText(_ direction: String) -> String {
    switch direction {
    case "left":
      return "向左绕行"
    case "right":
      return "向右绕行"
    case "forward":
      return "继续直行"
    case "stop":
      return "立即停下"
    case "slow":
      return "放慢速度"
    default:
      return "无法判断"
    }
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
