import UIKit

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
