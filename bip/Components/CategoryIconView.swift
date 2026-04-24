import SwiftUI

struct CategoryIconView: View {
    let category: Category?
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: category?.symbolName ?? "circle.grid.2x2")
            .font(.system(size: size * 0.72, weight: .medium))
            .foregroundStyle(category.map { Color(hex: $0.colorHex) } ?? BIPTheme.textSecondary)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    CategoryIconView(category: Category(name: "Home", colorHex: "#A0A0A0", symbolName: "house"))
        .padding()
        .background(BIPTheme.background)
}
