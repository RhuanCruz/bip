import SwiftUI

struct BIPTopBar: View {
    let activeView: MainViewMode
    let onDateTap: () -> Void
    let onTitleTap: () -> Void
    let onMoreTap: () -> Void

    var body: some View {
        HStack {
            if activeView == .tasks {
                Button(action: onDateTap) {
                    Image(systemName: "calendar")
                        .font(.system(size: 19, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(BIPTheme.elevated)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose date")
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }

            Spacer()

            Button(action: onTitleTap) {
                HStack(spacing: 4) {
                    Text(activeView.rawValue)
                        .font(.system(size: 22, weight: .bold))

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(BIPTheme.textSecondary)
                }
                .foregroundStyle(BIPTheme.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Switch main view")

            Spacer()

            Button(action: onMoreTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 19, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(BIPTheme.elevated)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More")
        }
        .foregroundStyle(BIPTheme.textPrimary)
        .padding(.horizontal, BIPSpacing.large)
        .padding(.top, BIPSpacing.large)
    }
}

#Preview {
    BIPTopBar(activeView: .tasks) {} onTitleTap: {} onMoreTap: {}
        .background(BIPTheme.background)
}
