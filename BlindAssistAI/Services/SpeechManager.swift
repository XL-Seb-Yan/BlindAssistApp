import AVFoundation
import Foundation

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
