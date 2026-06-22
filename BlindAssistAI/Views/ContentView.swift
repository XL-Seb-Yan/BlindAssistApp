import SwiftUI

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
