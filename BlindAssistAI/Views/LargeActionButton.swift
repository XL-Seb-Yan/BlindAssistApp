import SwiftUI

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
