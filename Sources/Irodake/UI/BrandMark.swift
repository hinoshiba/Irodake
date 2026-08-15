import SwiftUI

struct BrandMark: View {
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.15))
            RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.cyan, .indigo, .pink, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.18, height: size * 0.7)
                .rotationEffect(.degrees(7))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
