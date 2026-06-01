//
//  ContentView.swift
//  BlindAssistAI
//
//  Created by Jason Huang on 11/5/2026.
import SwiftUI
import AVFoundation
import UIKit
import Combine

// MARK: - Data Models

enum AssistantStatus: String {
  case idle = "未开始"
  case ready = "准备拍照"
  case analyzing = "正在分析"
  case completed = "分析完成"
  case paused = "已暂停"
}

enum RiskLevel: String {
  case low = "低风险"
  case medium = "中风险"
  case high = "高风险"
  case unknown = "无法判断"
}

struct VisionAnalysisResult {
  let riskLevel: RiskLevel
  let mainObstacle: String
  let direction: String
  let spokenResponse: String
}

// MARK: - Speech Manager

final class SpeechManager {
  private let synthesizer = AVSpeechSynthesizer()

  func speak(_ text: String, language: String = "zh-HK") {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = 0.48
    utterance.pitchMultiplier = 1.0
    utterance.volume = 1.0

    synthesizer.speak(utterance)
  }

  func stop() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
  }
}

// MARK: - Haptic Manager

final class HapticManager {
  func success() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
  }

  func warning() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
  }

  func error() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.error)
  }

  func lightTap() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
  }
}

// MARK: - Mock AI Analyzer

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

// MARK: - View Model

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

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
  let onImagePicked: (UIImage) -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraDevice = .rear
    picker.allowsEditing = false
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onImagePicked: onImagePicked)
  }

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let onImagePicked: (UIImage) -> Void

    init(onImagePicked: @escaping (UIImage) -> Void) {
      self.onImagePicked = onImagePicked
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage {
        onImagePicked(image)
      }

      picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}

// MARK: - Large Button

struct LargeActionButton: View {
  let title: String
  let systemImage: String
  let backgroundColor: Color
  let action: () -> Void
  let accessibilityText: String

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        Image(systemName: systemImage)
          .font(.title2)

        Text(title)
          .font(.title3)
          .fontWeight(.semibold)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(backgroundColor)
      .foregroundColor(.white)
      .cornerRadius(18)
    }
    .accessibilityLabel(accessibilityText)
    .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Main View

struct ContentView: View {
  @StateObject private var viewModel = AssistantViewModel()

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [
            Color.black,
            Color(red: 0.06, green: 0.08, blue: 0.16)
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            headerSection
            cameraPreviewSection
            statusCard
            resultCard
            actionButtons
            safetyNotice
          }
          .padding()
        }
      }
      .navigationTitle("BlindAssist AI")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $viewModel.showCamera) {
        CameraPicker { image in
          viewModel.handleCapturedImage(image)
        }
      }
      .alert("提示", isPresented: $viewModel.showAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(viewModel.alertMessage)
      }
    }
  }

  private var headerSection: some View {
    VStack(spacing: 12) {
      Image(systemName: "eye.circle.fill")
        .font(.system(size: 72))
        .foregroundColor(.blue)
        .accessibilityHidden(true)

      Text("助盲环境感知助手")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)

      Text("拍摄前方环境，并用 AI 模拟分析障碍物与风险。")
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("助盲环境感知助手，拍摄前方环境，并用人工智能模拟分析障碍物与风险。")
  }

  private var cameraPreviewSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("当前拍摄画面")
        .font(.headline)
        .foregroundColor(.white.opacity(0.7))

      ZStack {
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.white.opacity(0.1))
          .frame(height: 220)

        if let image = viewModel.capturedImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(height: 220)
            .clipped()
            .cornerRadius(20)
        } else {
          VStack(spacing: 10) {
            Image(systemName: "camera.fill")
              .font(.system(size: 42))
              .foregroundColor(.white.opacity(0.7))

            Text("尚未拍摄照片")
              .foregroundColor(.white.opacity(0.7))
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(viewModel.capturedImage == nil ? "尚未拍摄照片" : "已经拍摄一张照片")
  }

  private var statusCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("当前状态")
        .font(.headline)
        .foregroundColor(.white.opacity(0.7))

      HStack {
        Circle()
          .fill(viewModel.statusColor)
          .frame(width: 18, height: 18)
          .accessibilityHidden(true)

        Text(viewModel.status.rawValue)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundColor(.white)

        Spacer()
      }
    }
    .padding()
    .background(Color.white.opacity(0.12))
    .cornerRadius(20)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("当前状态，\(viewModel.status.rawValue)")
  }

  private var resultCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("AI 提示")
        .font(.headline)
        .foregroundColor(.white.opacity(0.7))

      Text(viewModel.latestResult.spokenResponse)
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .fixedSize(horizontal: false, vertical: true)

      Divider()
        .background(Color.white.opacity(0.3))

      VStack(alignment: .leading, spacing: 8) {
        infoRow(title: "风险等级", value: viewModel.latestResult.riskLevel.rawValue)
        infoRow(title: "主要情况", value: viewModel.latestResult.mainObstacle)
        infoRow(title: "建议方向", value: viewModel.directionText(viewModel.latestResult.direction))
      }
    }
    .padding()
    .background(viewModel.resultBackgroundColor)
    .cornerRadius(20)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("AI 提示，\(viewModel.latestResult.spokenResponse)。风险等级，\(viewModel.latestResult.riskLevel.rawValue)。主要情况，\(viewModel.latestResult.mainObstacle)。")
  }

  private func infoRow(title: String, value: String) -> some View {
    HStack(alignment: .top) {
      Text(title + "：")
        .font(.body)
        .foregroundColor(.white.opacity(0.75))

      Text(value)
        .font(.body)
        .fontWeight(.medium)
        .foregroundColor(.white)

      Spacer()
    }
  }

  private var actionButtons: some View {
    VStack(spacing: 14) {
      LargeActionButton(
        title: "拍照分析",
        systemImage: "camera.fill",
        backgroundColor: .green,
        action: {
          viewModel.openCamera()
        },
        accessibilityText: "打开摄像头，拍摄前方环境并分析"
      )

      LargeActionButton(
        title: "重新拍照",
        systemImage: "arrow.clockwise.camera.fill",
        backgroundColor: .blue,
        action: {
          viewModel.openCamera()
        },
        accessibilityText: "重新拍摄前方环境"
      )

      LargeActionButton(
        title: "暂停识别",
        systemImage: "pause.fill",
        backgroundColor: .orange,
        action: {
          viewModel.pause()
        },
        accessibilityText: "暂停识别"
      )

      LargeActionButton(
        title: "模拟高风险",
        systemImage: "exclamationmark.triangle.fill",
        backgroundColor: .red,
        action: {
          viewModel.simulateHighRisk()
        },
        accessibilityText: "模拟高风险场景"
      )

      LargeActionButton(
        title: "紧急求助",
        systemImage: "phone.fill",
        backgroundColor: .purple,
        action: {
          viewModel.emergencyHelp()
        },
        accessibilityText: "紧急求助按钮"
      )
    }
  }

  private var safetyNotice: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("安全提示")
        .font(.headline)
        .foregroundColor(.yellow)

      Text("本 App 目前是学习与演示原型，只能作为环境感知辅助工具，不能替代导盲杖、导盲犬或真人协助。当前版本已加入真实拍照功能，但 AI 分析仍为模拟结果。")
        .font(.footnote)
        .foregroundColor(.white.opacity(0.78))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding()
    .background(Color.yellow.opacity(0.12))
    .cornerRadius(16)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("安全提示，本 App 目前是学习与演示原型，只能作为环境感知辅助工具，不能替代导盲杖、导盲犬或真人协助。当前版本已加入真实拍照功能，但人工智能分析仍为模拟结果。")
  }
}

#Preview {
  ContentView()
}
