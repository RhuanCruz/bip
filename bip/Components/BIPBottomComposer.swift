import SwiftUI

struct BIPBottomComposer: View {
    @Binding var text: String
    @Binding var isVoiceModeActive: Bool
    @StateObject private var voiceInput = VoiceInputMonitor()

    let placeholder: String
    let contextTask: Task?
    let onSubmit: () -> Void
    let onClearContext: () -> Void

    var body: some View {
        VStack(spacing: BIPSpacing.small) {
            if let contextTask {
                ContextBar(taskTitle: contextTask.title, onClose: onClearContext)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: BIPSpacing.medium) {
                Button(action: onSubmit) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white.opacity(0.92), lineWidth: 1.4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task")

                Group {
                    if voiceInput.isRecording {
                        VoiceWaveformView(levels: voiceInput.levels)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .accessibilityLabel("Voice input waveform")
                    } else {
                        TextField(placeholder, text: $text)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .submitLabel(.done)
                            .onSubmit(onSubmit)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        if voiceInput.isRecording {
                            voiceInput.stop()
                        } else {
                            voiceInput.start()
                        }
                    }
                } label: {
                    Image(systemName: "mic")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(voiceInput.isRecording ? BIPTheme.warmAccent : BIPTheme.textPrimary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle voice mode")
            }
            .foregroundStyle(BIPTheme.textPrimary)
            .padding(.leading, BIPSpacing.medium)
            .padding(.trailing, BIPSpacing.large)
            .frame(height: 54)
            .unifiedComposerGlass(cornerRadius: 24)
        }
        .padding(.horizontal, BIPSpacing.small)
        .padding(.bottom, BIPSpacing.small)
        .animation(.snappy(duration: 0.22), value: contextTask?.id)
        .animation(.snappy(duration: 0.18), value: voiceInput.isRecording)
        .onChange(of: voiceInput.isRecording) { _, isRecording in
            isVoiceModeActive = isRecording
        }
        .onDisappear {
            voiceInput.stop()
        }
    }
}

private struct VoiceWaveformView: View {
    let levels: [CGFloat]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(Color.white.opacity(0.42 + level * 0.48))
                    .frame(width: 4, height: 7 + level * 36)
            }
        }
        .frame(height: 42, alignment: .center)
    }
}

private extension View {
    @ViewBuilder
    func unifiedComposerGlass(cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(
                    .regular
                        .tint(Color.white.opacity(0.10))
                        .interactive(),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @State var voice = false
    let category = Category(name: "Home", colorHex: "#A0A0A0", symbolName: "house")
    let task = Task(title: "Sair com os cachorros", category: category)
    BIPBottomComposer(text: $text, isVoiceModeActive: $voice, placeholder: "Add tasks in plain english", contextTask: task) {} onClearContext: {}
        .background(BIPTheme.background)
}
