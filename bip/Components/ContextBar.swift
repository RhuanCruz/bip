import SwiftUI

struct ContextBar: View {
    let taskTitle: String
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: BIPSpacing.medium) {
            Image(systemName: "arrow.uturn.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BIPTheme.textPrimary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Edit or Add sub task")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BIPTheme.textPrimary)

                Text(taskTitle)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .foregroundStyle(BIPTheme.textSecondary)
            }

            Spacer(minLength: BIPSpacing.small)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BIPTheme.textPrimary)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(BIPTheme.textPrimary, lineWidth: 1.3))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear task context")
        }
        .padding(.horizontal, BIPSpacing.large)
        .padding(.vertical, BIPSpacing.medium)
        .background(BIPTheme.background.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ContextBar(taskTitle: "Sair com os cachorros") {}
        .padding()
        .background(BIPTheme.background)
}
