import SwiftUI

struct BIPPostComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var postBody = ""
    @State private var selectedMediaCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create post")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(BIPTheme.textPrimary)

                        Text("Write a daily update and attach visuals later.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BIPTheme.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: BIPSpacing.small) {
                        Text("Title")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BIPTheme.textSecondary)

                        TextField("What are you building?", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(BIPTheme.textPrimary)
                            .padding(BIPSpacing.medium)
                            .background(BIPTheme.sheetField)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: BIPSpacing.small) {
                        Text("Post")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BIPTheme.textSecondary)

                        TextEditor(text: $postBody)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 180, alignment: .topLeading)
                            .padding(BIPSpacing.medium)
                            .background(BIPTheme.sheetField)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(BIPTheme.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: BIPSpacing.small) {
                        HStack {
                            Text("Media")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BIPTheme.textSecondary)

                            Spacer()

                            Button("Add image") {
                                selectedMediaCount += 1
                            }
                            .font(.system(size: 13, weight: .semibold))
                        }

                        HStack(spacing: BIPSpacing.small) {
                            ForEach(0..<max(selectedMediaCount, 1), id: \.self) { index in
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(BIPTheme.elevated)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 20, weight: .semibold))
                                            Text(index == 0 ? "Cover image" : "Extra image")
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundStyle(BIPTheme.textSecondary)
                                    )
                                    .frame(height: 120)
                            }
                        }
                    }
                }
                .padding(BIPSpacing.large)
            }
            .background(BIPTheme.sheetBackground)
            .navigationTitle("BIP Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    BIPPostComposerSheet()
}
