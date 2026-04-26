import SwiftUI

struct BIPPostBar: View {
    let onAddPost: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onAddPost) {
                HStack(spacing: BIPSpacing.medium) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.white)

                    Text("Add post")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BIPTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BIPTheme.textSecondary)
                }
                .padding(.horizontal, BIPSpacing.medium)
                .padding(.vertical, 14)
                .background(BIPTheme.sheetField, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, BIPSpacing.large)
        .padding(.bottom, BIPSpacing.large)
    }
}

#Preview {
    BIPPostBar(onAddPost: {})
        .background(BIPTheme.background)
}
