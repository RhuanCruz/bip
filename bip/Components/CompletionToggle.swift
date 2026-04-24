import SwiftUI

struct CompletionToggle: View {
    @Binding var isCompleted: Bool

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.18)) {
                isCompleted.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.white : BIPTheme.elevated)
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BIPTheme.success)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? "Mark incomplete" : "Mark complete")
    }
}

#Preview {
    @Previewable @State var completed = true
    CompletionToggle(isCompleted: $completed)
        .padding()
        .background(BIPTheme.background)
}
