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
    var body: some View {
        TabView {
            NavigationStack { BrowseView() }
                .tabItem { Label("现在观看", systemImage: "play.rectangle.fill") }
            NavigationStack { LibraryView() }
                .tabItem { Label("资料库", systemImage: "books.vertical.fill") }
            NavigationStack { SearchView() }
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
            NavigationStack { LiveView() }
                .tabItem { Label("直播", systemImage: "tv") }
            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
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

struct MediaGrid: View {
    let items: [Media]
    @EnvironmentObject private var session: LunaSession
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 36)], alignment: .leading, spacing: 44) {
            ForEach(items) { item in
                NavigationLink(value: item) {
                    VStack(alignment: .leading, spacing: 14) {
                        AsyncImage(url: session.images(item.poster)) { image in image.resizable().scaledToFill() }
                        placeholder: { Rectangle().fill(.quaternary).overlay { Image(systemName: "film").font(.largeTitle).foregroundStyle(.secondary) } }
                        .frame(height: 300).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                        Text(item.title).font(.headline).lineLimit(2).frame(height: 64, alignment: .topLeading)
                        Text([item.year, item.sourceName, item.rating.isEmpty ? "" : "★ " + item.rating].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        if item.duration > 0 && item.position > 0 {
                            ProgressView(value: min(1, item.position / item.duration)).tint(.white)
                        }
                    }.padding(12)
                }.buttonStyle(.card)
                .accessibilityLabel(item.title + (item.position > 0 ? "，继续观看" : ""))
            }
        }.padding(.vertical, 24)
    }
}
