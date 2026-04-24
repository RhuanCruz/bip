import SwiftUI

struct BIPBottomComposer: View {
    @Binding var text: String
    @Binding var isVoiceModeActive: Bool
    @StateObject private var voiceInput = VoiceInputMonitor()

    let didCompleteProcessing: Bool
    let isProcessing: Bool
    let placeholder: String
    let contextTask: Task?
    let showsContextBar: Bool
    let onSubmit: () -> Void
    let onVoiceSubmit: (URL) -> Void
    let onClearContext: () -> Void

    var body: some View {
        VStack(spacing: BIPSpacing.small) {
            if showsContextBar, let contextTask {
                ContextBar(taskTitle: contextTask.title, onClose: onClearContext)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: BIPSpacing.medium) {
                Button(action: voiceInput.isRecording ? cancelVoiceInput : onSubmit) {
                    Image(systemName: voiceInput.isRecording ? "xmark" : "plus")
                        .font(.system(size: voiceInput.isRecording ? 15 : 18, weight: .bold))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white.opacity(0.92), lineWidth: 1.4))
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.45 : 1)
                .accessibilityLabel(voiceInput.isRecording ? "Cancel voice input" : "Add task")

                Group {
                    if isProcessing {
                        HStack(spacing: BIPSpacing.small) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(BIPTheme.textPrimary)

                            Text("Processing...")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(BIPTheme.textSecondary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .accessibilityLabel("Processing input")
                    } else if didCompleteProcessing {
                        HStack(spacing: BIPSpacing.small) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(BIPTheme.success)

                            Text("Done")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(BIPTheme.success)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .accessibilityLabel("Input processed")
                    } else if voiceInput.isRecording {
                        VoiceWaveformView(levels: voiceInput.levels)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .accessibilityLabel("Voice input waveform")
                    } else {
                        TextField(placeholder, text: $text)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .submitLabel(.done)
                            .onSubmit(onSubmit)
                            .disabled(isProcessing)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: trailingAction) {
                    trailingActionIcon
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.45 : 1)
                .accessibilityLabel(voiceInput.isRecording ? "Send voice input" : "Start voice input")
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
        .animation(.snappy(duration: 0.18), value: isProcessing)
        .animation(.snappy(duration: 0.18), value: didCompleteProcessing)
        .onChange(of: voiceInput.isRecording) { _, isRecording in
            isVoiceModeActive = isRecording
        }
        .onDisappear {
            voiceInput.stop()
        }
    }

    @ViewBuilder
    private var trailingActionIcon: some View {
        if didCompleteProcessing {
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 36, height: 36)
                .background(BIPTheme.success, in: Circle())
        } else if voiceInput.isRecording || hasText {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 36, height: 36)
                .background(BIPTheme.warmAccent, in: Circle())
        } else {
            Image(systemName: "mic")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(BIPTheme.textPrimary)
                .frame(width: 36, height: 36)
        }
    }

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func trailingAction() {
        if voiceInput.isRecording {
            sendVoiceInput()
        } else if hasText {
            onSubmit()
        } else {
            startVoiceInput()
        }
    }

    private func startVoiceInput() {
        withAnimation(.snappy(duration: 0.18)) {
            voiceInput.start()
        }
    }

    private func cancelVoiceInput() {
        withAnimation(.snappy(duration: 0.18)) {
            voiceInput.stop()
        }
    }

    private func sendVoiceInput() {
        var fileURL: URL?
        withAnimation(.snappy(duration: 0.18)) {
            fileURL = voiceInput.finishRecording()
        }

        if let fileURL {
            onVoiceSubmit(fileURL)
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
    BIPBottomComposer(text: $text, isVoiceModeActive: $voice, didCompleteProcessing: false, isProcessing: false, placeholder: "Add tasks in plain english", contextTask: task, showsContextBar: true, onSubmit: {}, onVoiceSubmit: { _ in }, onClearContext: {})
        .background(BIPTheme.background)
}
