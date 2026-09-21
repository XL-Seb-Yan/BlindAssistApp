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
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            viewModel.toggleLanguage()
          } label: {
            Text(viewModel.language.toggleTitle)
              .fontWeight(.semibold)
          }
          .accessibilityLabel(viewModel.language.toggleAccessibilityLabel)
        }
      }
      .sheet(isPresented: $viewModel.showCamera) {
        CameraPicker { image in
          viewModel.handleCapturedImage(image)
        }
      }
      .alert(viewModel.text.alertTitle, isPresented: $viewModel.showAlert) {
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

      Text(viewModel.text.headerTitle)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .multilineTextAlignment(.center)

      Text(viewModel.text.headerSubtitle)
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(viewModel.text.headerAccessibilityLabel)
  }

  private var cameraPreviewSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(viewModel.text.cameraSectionTitle)
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

            Text(viewModel.text.noPhotoText)
              .foregroundColor(.white.opacity(0.7))
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(viewModel.capturedImage == nil ? viewModel.text.noPhotoText : viewModel.text.photoCapturedAccessibilityLabel)
  }

  private var statusCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(viewModel.text.currentStatusTitle)
        .font(.headline)
        .foregroundColor(.white.opacity(0.7))

      HStack {
        Circle()
          .fill(viewModel.statusColor)
          .frame(width: 18, height: 18)
          .accessibilityHidden(true)

        Text(viewModel.statusText)
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
    .accessibilityLabel(viewModel.text.statusAccessibilityLabel(statusText: viewModel.statusText))
  }

  private var resultCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(viewModel.text.aiTipTitle)
        .font(.headline)
        .foregroundColor(.white.opacity(0.7))

      Text(viewModel.spokenResponseText)
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .fixedSize(horizontal: false, vertical: true)

      Divider()
        .background(Color.white.opacity(0.3))

      VStack(alignment: .leading, spacing: 8) {
        infoRow(title: viewModel.text.riskLevelTitle, value: viewModel.riskLevelText)
        infoRow(title: viewModel.text.mainSituationTitle, value: viewModel.mainObstacleText)
        infoRow(title: viewModel.text.suggestedDirectionTitle, value: viewModel.directionText(viewModel.latestResult.direction))
      }
    }
    .padding()
    .background(viewModel.resultBackgroundColor)
    .cornerRadius(20)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      viewModel.text.resultAccessibilityLabel(
        response: viewModel.spokenResponseText,
        riskLevel: viewModel.riskLevelText,
        obstacle: viewModel.mainObstacleText
      )
    )
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
        title: viewModel.text.scanButtonTitle,
        systemImage: "camera.fill",
        backgroundColor: .green,
        action: {
          viewModel.openCamera()
        },
        accessibilityText: viewModel.text.scanButtonAccessibility
      )

      LargeActionButton(
        title: viewModel.text.retakeButtonTitle,
        systemImage: "arrow.clockwise.camera.fill",
        backgroundColor: .blue,
        action: {
          viewModel.openCamera()
        },
        accessibilityText: viewModel.text.retakeButtonAccessibility
      )

      LargeActionButton(
        title: viewModel.text.pauseButtonTitle,
        systemImage: "pause.fill",
        backgroundColor: .orange,
        action: {
          viewModel.pause()
        },
        accessibilityText: viewModel.text.pauseButtonAccessibility
      )

      LargeActionButton(
        title: viewModel.text.simulateHighRiskButtonTitle,
        systemImage: "exclamationmark.triangle.fill",
        backgroundColor: .red,
        action: {
          viewModel.simulateHighRisk()
        },
        accessibilityText: viewModel.text.simulateHighRiskButtonAccessibility
      )

      LargeActionButton(
        title: viewModel.text.emergencyHelpButtonTitle,
        systemImage: "phone.fill",
        backgroundColor: .purple,
        action: {
          viewModel.emergencyHelp()
        },
        accessibilityText: viewModel.text.emergencyHelpButtonAccessibility
      )
    }
  }

  private var safetyNotice: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(viewModel.text.safetyTitle)
        .font(.headline)
        .foregroundColor(.yellow)

      Text(viewModel.text.safetyText)
        .font(.footnote)
        .foregroundColor(.white.opacity(0.78))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding()
    .background(Color.yellow.opacity(0.12))
    .cornerRadius(16)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(viewModel.text.safetyTitle), \(viewModel.text.safetyText)")
  }
}

#Preview {
  ContentView()
}
