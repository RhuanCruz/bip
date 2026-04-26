import SwiftUI

struct BIPFeedView: View {
    let onAddPost: () -> Void

    private let posts: [BIPFeedPost] = [
        BIPFeedPost(
            authorName: "Rhuan",
            handle: "@zurc.dev",
            timestamp: "2h",
            projectTitle: "FocusTimer",
            projectSubtitle: "App de Pomodoro colaborativo",
            body: "Hoje implementei o timer principal com suporte a salas em tempo real. Também ajustei o design da tela de sessão e corrigi alguns bugs no envio de convites.",
            metrics: ("Tasks concluídas", "7/9", "checkmark.circle.fill", BIPTheme.success),
            images: [
                BIPFeedImage(title: "Progress shot", assetName: "IMG_2644"),
                BIPFeedImage(title: "Workspace", assetName: "IMG_2656"),
                BIPFeedImage(title: "Build log", assetName: "IMG_2657")
            ],
            likes: 24,
            comments: 6
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: BIPSpacing.large) {
                ForEach(posts) { post in
                    BIPFeedCard(post: post)
                }
            }
            .padding(.horizontal, BIPSpacing.large)
            .padding(.top, BIPSpacing.medium)
            .padding(.bottom, 96)
        }
        .background(BIPTheme.background)
    }

}

private struct BIPFeedCard: View {
    let post: BIPFeedPost
    @State private var isBodyExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: BIPSpacing.medium) {
            HStack(alignment: .center, spacing: BIPSpacing.medium) {
                Image("founder").resizable().clipShape(Circle()).frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading ) {
                            Text(post.authorName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(BIPTheme.textPrimary)

                            Text(post.handle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(BIPTheme.textSecondary)
                        }

                    }
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(BIPTheme.textSecondary)
                    .padding(.top, 6)
            }

            // Corpo com truncamento e botão "Ver mais"
            VStack(alignment: .leading, spacing: 6) {
                Text(post.body)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(BIPTheme.textPrimary)
                    .lineSpacing(6)
                    .lineLimit(isBodyExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isBodyExpanded.toggle()
                    }
                }) {
                    Text(isBodyExpanded ? "Ver menos" : "Ver mais")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BIPTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            // Carrossel horizontal landscape
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BIPSpacing.small) {
                    ForEach(post.images) { image in
                        BIPFeedImageTile(image: image)
                    }
                }
            }

           

            HStack(spacing: BIPSpacing.large) {
                HStack(spacing: 8) {
                    Image(systemName: "heart")
                    Text("\(post.likes)")
                }

                HStack(spacing: 8) {
                    Image(systemName: "bubble.right")
                    Text("\(post.comments)")
                }
                
                Spacer()
                Text("\(post.timestamp)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BIPTheme.textSecondary)
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(BIPTheme.textSecondary)
            .padding(.top, 2)
        }
        .padding(BIPSpacing.large)
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

}

private struct BIPFeedImageTile: View {
    let image: BIPFeedImage

    var body: some View {
        Image(image.assetName)
            .resizable()
            .scaledToFill()
        .frame(width: 220, height: 110)
        .overlay(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .bottomLeading) {
                Text(image.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .padding(10)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct BIPFeedPost: Identifiable {
    let id = UUID()
    let authorName: String
    let handle: String
    let timestamp: String
    let projectTitle: String
    let projectSubtitle: String
    let body: String
    let metrics: (String, String, String, Color)
    let images: [BIPFeedImage]
    let likes: Int
    let comments: Int
}

private struct BIPFeedImage: Identifiable {
    let id = UUID()
    let title: String
    let assetName: String
}

#Preview {
    BIPFeedView(onAddPost: {})
        .background(BIPTheme.background)
}
