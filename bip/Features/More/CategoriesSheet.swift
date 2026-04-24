import SwiftData
import SwiftUI

struct CategoriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var newName = ""
    @State private var selectedColorHex = "#A0A0A0"
    @State private var selectedSymbolName = "circle.grid.2x2"

    private let colorPresets = [
        "#A0A0A0",
        "#2F80ED",
        "#27AE60",
        "#B07A2A",
        "#EB5757",
        "#9B51E0",
    ]

    private let symbolPresets = [
        "house",
        "figure.strengthtraining.traditional",
        "books.vertical",
        "briefcase",
        "cart",
        "checklist",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BIPSpacing.extraLarge) {
                    createSection
                    listSection
                }
                .padding(BIPSpacing.extraLarge)
            }
            .background(BIPTheme.sheetBackground)
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BIPTheme.sheetBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var createSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            sectionTitle("New Category")

            VStack(alignment: .leading, spacing: BIPSpacing.medium) {
                HStack(spacing: BIPSpacing.medium) {
                    CategoryIconPreview(symbolName: selectedSymbolName, colorHex: selectedColorHex)

                    TextField("Category name", text: $newName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(BIPTheme.textPrimary)
                        .tint(BIPTheme.textPrimary)
                        .submitLabel(.done)
                        .onSubmit(createCategory)
                }

                HStack(spacing: BIPSpacing.small) {
                    ForEach(colorPresets, id: \.self) { colorHex in
                        Button {
                            selectedColorHex = colorHex
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColorHex == colorHex ? Color.white : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BIPSpacing.small) {
                        ForEach(symbolPresets, id: \.self) { symbolName in
                            Button {
                                selectedSymbolName = symbolName
                            } label: {
                                Image(systemName: symbolName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(selectedSymbolName == symbolName ? Color.white : BIPTheme.textSecondary)
                                    .frame(width: 38, height: 34)
                                    .background(selectedSymbolName == symbolName ? BIPTheme.sheetFieldLight : BIPTheme.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button(action: createCategory) {
                    Label("Create Category", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(canCreate ? BIPTheme.sheetFieldLight : BIPTheme.elevated.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(BIPTheme.textPrimary)
                .disabled(!canCreate)
            }
            .padding(BIPSpacing.large)
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BIPTheme.sheetStroke, lineWidth: 1)
            )
        }
    }

    private var listSection: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            sectionTitle("All Categories")

            VStack(spacing: 0) {
                ForEach(categories) { category in
                    HStack(spacing: BIPSpacing.medium) {
                        CategoryIconPreview(symbolName: category.symbolName, colorHex: category.colorHex)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(BIPTheme.textPrimary)

                            Text(category.taskCount == 1 ? "1 task" : "\(category.taskCount) tasks")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(BIPTheme.textSecondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            modelContext.delete(category)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, BIPSpacing.large)
                    .frame(height: 64)

                    if category.id != categories.last?.id {
                        Divider()
                            .background(BIPTheme.sheetStroke)
                            .padding(.leading, 62)
                    }
                }
            }
            .background(BIPTheme.sheetField)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BIPTheme.sheetStroke, lineWidth: 1)
            )
        }
    }

    private var canCreate: Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !categories.contains { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    private func createCategory() {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canCreate else { return }

        modelContext.insert(Category(
            name: trimmedName,
            colorHex: selectedColorHex,
            symbolName: selectedSymbolName
        ))
        newName = ""
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(BIPTheme.textSecondary)
    }
}

private struct CategoryIconPreview: View {
    let symbolName: String
    let colorHex: String

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color(hex: colorHex))
            .frame(width: 38, height: 38)
            .background(BIPTheme.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

#Preview {
    CategoriesSheet()
        .modelContainer(BIPPreviewData.container())
}
