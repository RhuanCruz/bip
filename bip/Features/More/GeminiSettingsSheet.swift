import SwiftUI

struct GeminiSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var statusText: String?
    @State private var isSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                    VStack(alignment: .leading, spacing: BIPSpacing.small) {
                        Text("Gemini API Key")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(BIPTheme.textPrimary)

                        Text("Stored only on this device in Keychain. It is not synced with SwiftData or CloudKit.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BIPTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: BIPSpacing.medium) {
                        SecureField("Paste your Gemini API key", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(BIPTheme.textPrimary)
                            .tint(BIPTheme.textPrimary)
                            .padding(BIPSpacing.medium)
                            .background(BIPTheme.sheetField)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BIPTheme.sheetStroke, lineWidth: 1)
                            )

                        HStack(spacing: BIPSpacing.medium) {
                            Button("Save", action: save)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(BIPTheme.warmAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(Color.white)

                            Button("Remove", role: .destructive, action: remove)
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(BIPTheme.sheetField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        if let statusText {
                            Text(statusText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(isSaved ? BIPTheme.success : BIPTheme.textSecondary)
                        }
                    }
                }
                .padding(BIPSpacing.large)
            }
            .background(BIPTheme.sheetBackground)
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if GeminiAPIKeyStore.load() != nil {
                statusText = "A Gemini API key is saved on this device."
                isSaved = true
            }
        }
    }

    private func save() {
        do {
            try GeminiAPIKeyStore.save(apiKey)
            apiKey = ""
            isSaved = true
            statusText = "Saved locally in Keychain."
        } catch {
            isSaved = false
            statusText = error.localizedDescription
        }
    }

    private func remove() {
        GeminiAPIKeyStore.delete()
        apiKey = ""
        isSaved = false
        statusText = "Removed from this device."
    }
}

#Preview {
    GeminiSettingsSheet()
}
