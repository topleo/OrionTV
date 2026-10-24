import SwiftUI

@main struct OrionTVNativeApp: App {
    @StateObject private var session = LunaSession()
    var body: some Scene {
        WindowGroup {
            Group {
                if session.starting { ProgressView("正在连接 LunaTV…") }
                else if session.authenticated { NativeTabs() }
                else { LoginView() }
            }
            .environmentObject(session)
            .preferredColorScheme(.dark)
            .task { await session.bootstrap() }
        }
    }
}

private struct NativeTabs: View {
    @State private var selected = "hot"
    @State private var tags: [String: String] = [:]
    private var category: BrowseCategory? { BrowseCategory.all.first { $0.id == selected } }
    private func tag(for category: BrowseCategory) -> Binding<String> {
        Binding(get: { tags[category.id] ?? category.tags[0] }, set: { tags[category.id] = $0 })
    }
    private var tabs: some View {
        TabView(selection: $selected) {
            Tab("搜索", systemImage: "magnifyingglass", value: "search", role: .search) {
                NavigationStack { SearchView() }
            }
            ForEach(BrowseCategory.all) { category in
                Tab(category.title, systemImage: category.symbol, value: category.id) {
                    NavigationStack { BrowseView(category: category, tag: tag(for: category)) }
                }
            }
            Tab("资料库", systemImage: "books.vertical.fill", value: "library") {
                NavigationStack { LibraryView() }
            }
            Tab("直播", systemImage: "tv.inset.filled", value: "live") {
                NavigationStack { LiveView() }
            }
            Tab("设置", systemImage: "gearshape.fill", value: "settings") {
                NavigationStack { SettingsView() }
            }
        }.tabViewStyle(.sidebarAdaptable)
    }
    @ViewBuilder var body: some View {
        if #available(tvOS 27.0, *) {
            tabs
                .tabViewSidebarHeader {
                    Label("OrionTV", systemImage: "play.rectangle.fill")
                        .font(.title2.weight(.semibold)).padding(.vertical, 16)
                }
                .tabViewSidebarFooter {
                    if let category, category.tags.count > 1 {
                        Menu {
                            Picker("内容筛选", selection: tag(for: category)) {
                                ForEach(category.tags, id: \.self) { Text($0).tag($0) }
                            }
                        } label: {
                            Label(tags[category.id] ?? category.tags[0], systemImage: "line.3.horizontal.decrease")
                        }.padding(.vertical, 12)
                    }
                }
        } else { tabs }
    }
}

struct LoginView: View {
    @EnvironmentObject private var session: LunaSession
    @State private var address = ""
    @State private var username = ""
    @State private var password = ""
    @State private var working = false
    @State private var error: String?
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "play.rectangle.fill").font(.system(size: 64)).accessibilityHidden(true)
            Text("OrionTV").font(.largeTitle.bold())
            Text("连接家中的 LunaTV").font(.title3).foregroundStyle(.secondary)
            TextField("服务器地址", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("用户名", text: $username).textContentType(.username).textInputAutocapitalization(.never).autocorrectionDisabled()
            SecureField("密码", text: $password).textContentType(.password)
            if let message = error ?? session.message { Text(message).foregroundStyle(.orange).font(.callout).multilineTextAlignment(.center) }
            if working { ProgressView("正在登录…") }
            Button("登录") {
                working = true; error = nil
                Task {
                    do { try await session.login(address: address, username: username, password: password); password = "" }
                    catch { self.error = error.localizedDescription }
                    working = false
                }
            }.buttonStyle(.borderedProminent).disabled(working || address.isEmpty)
        }
        .frame(maxWidth: 720).padding(60)
        .onAppear { address = session.server }
    }
}

struct EmptyState: View {
    var title: String
    var subtitle: String = ""
    var symbol = "film"
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: symbol).font(.system(size: 52)).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(title).font(.title2)
            if !subtitle.isEmpty { Text(subtitle).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center) }
        }.frame(maxWidth: .infinity, minHeight: 250).padding(40)
    }
}

private struct GridWidthPreference: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct MediaGrid: View {
    let items: [Media]
    var onApproachEnd: (() -> Void)? = nil
    @State private var availableWidth: CGFloat = 0
    var body: some View {
        let layout = PosterGridLayout(width: Double(availableWidth), itemCount: items.count)
        LazyVStack(alignment: .leading, spacing: PosterGridLayout.verticalGap) {
            if availableWidth > 0 {
                ForEach(0..<layout.rowCount, id: \.self) { row in
                    HStack(alignment: .top, spacing: PosterGridLayout.horizontalGap) {
                        ForEach(Array(layout.indices(in: row)), id: \.self) { index in
                            PosterCard(item: items[index], layout: layout)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: layout.cellHeight, alignment: .leading)
                    // The entire row (including an incomplete row's empty columns)
                    // guides directional movement to its nearest actual poster.
                    .focusSection()
                    .onAppear { if row == layout.rowCount - 1 { onApproachEnd?() } }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 28)
        .background {
            GeometryReader { proxy in Color.clear.preference(key: GridWidthPreference.self, value: proxy.size.width) }
        }
        .onPreferenceChange(GridWidthPreference.self) { width in
            if abs(width - availableWidth) > 1 { availableWidth = width }
        }
    }
}

private struct PosterCard: View {
    let item: Media
    let layout: PosterGridLayout
    @EnvironmentObject private var session: LunaSession
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(value: item) {
                AsyncImage(url: session.images(item.poster)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.white.opacity(0.07))
                        .overlay { Image(systemName: "film").font(.largeTitle).foregroundStyle(.secondary) }
                }
                .frame(width: layout.cardWidth, height: layout.posterHeight)
                .clipped().clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(alignment: .bottom) {
                    if item.duration > 0 && item.position > 0 {
                        ProgressView(value: min(1, item.position / item.duration))
                            .tint(.white).padding(12)
                    }
                }
            }
            .buttonStyle(.card)
            .frame(width: layout.cardWidth, height: layout.posterHeight)
            .padding(.bottom, 24)
            .accessibilityLabel(item.title + (item.position > 0 ? "，继续观看" : ""))
            .accessibilityIdentifier("poster-" + item.id)
            Text(item.title).font(.system(size: 24, weight: .medium))
                .lineLimit(2).frame(width: layout.cardWidth, height: 62, alignment: .topLeading)
            Text([item.year, item.sourceName, item.rating.isEmpty ? "" : "★ " + item.rating]
                .filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.system(size: 20)).foregroundStyle(.secondary)
                .lineLimit(1).frame(width: layout.cardWidth, height: 28, alignment: .leading)
        }.frame(width: layout.cardWidth, height: layout.cellHeight, alignment: .topLeading)
    }
}
