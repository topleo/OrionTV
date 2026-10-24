import SwiftUI

struct BrowseView: View {
    let category: BrowseCategory
    @Binding var tag: String
    @EnvironmentObject private var session: LunaSession
    @State private var page = MediaPage()
    @State private var loading = false
    @State private var error: String?
    @State private var generation = UUID()
    private var filterID: String { category.id + ":" + tag }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.title).font(.system(size: 48, weight: .bold))
                    Text(category.tags.count > 1 ? tag : "精选内容，发现下一部想看的影片。")
                        .font(.system(size: 24)).foregroundStyle(.secondary)
                    if #unavailable(tvOS 27.0) {
                        if category.tags.count > 1 {
                            Picker("筛选", selection: $tag) {
                                ForEach(category.tags, id: \.self) { Text($0).tag($0) }
                            }.pickerStyle(.menu)
                        }
                    }
                }.padding(.top, 30).padding(.bottom, 8)
                MediaGrid(items: page.items) {
                    guard !loading && page.hasMore && error == nil else { return }
                    Task { await load(reset: false) }
                }
                if loading { HStack { Spacer(); ProgressView("正在加载…"); Spacer() }.padding(32) }
                if let error {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(error).foregroundStyle(.secondary)
                        Button("重试加载") { Task { await load(reset: page.items.isEmpty) } }
                    }.padding(.vertical, 24)
                } else if page.items.isEmpty && !loading {
                    EmptyState(title: "没有找到影片", subtitle: "试试侧栏中的其他分类，或前往搜索。")
                }
            }.padding(.horizontal, 64).padding(.bottom, 44)
        }
        .background {
            LinearGradient(colors: [Color(red: 0.035, green: 0.045, blue: 0.065), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: filterID) { await load(reset: true) }
        .navigationDestination(for: Media.self) { DetailView(original: $0) }
    }
    private func load(reset: Bool) async {
        if reset { generation = UUID(); page = MediaPage(); loading = false }
        guard !loading && page.hasMore else { return }
        loading = true; error = nil
        let token = generation
        do {
            let result = try await session.discover(category: category, tag: tag, start: page.offset)
            try Task.checkCancellation(); guard generation == token else { return }
            page.append(result)
        } catch {
            if generation == token && !Task.isCancelled { self.error = error.localizedDescription }
        }
        if generation == token { loading = false }
    }
}

struct SearchView: View {
    @EnvironmentObject private var session: LunaSession
    @State private var query = ""
    @State private var submitted = ""
    @State private var revision = 0
    @State private var items: [Media] = []
    @State private var loading = false
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("搜索").font(.largeTitle.bold())
            HStack {
                TextField("影片或剧集名称", text: $query).onSubmit { submit() }
                Button("搜索", systemImage: "magnifyingglass") { submit() }.disabled(query.isEmpty)
            }
            ScrollView {
                if loading { ProgressView("正在搜索各个视频源…").padding(50) }
                MediaGrid(items: items)
                if let error { EmptyState(title: "搜索未完成", subtitle: error, symbol: "wifi.exclamationmark") }
                else if !loading && items.isEmpty { EmptyState(title: submitted.isEmpty ? "寻找想看的影片" : "没有找到相关影片", subtitle: submitted.isEmpty ? "使用遥控器输入，或用 iPhone 键盘输入。" : "试试更完整的名称或其他关键词。", symbol: "magnifyingglass") }
            }
        }.padding(.horizontal, 64).padding(.top, 24)
        .task(id: revision) {
            guard !submitted.isEmpty else { return }; loading = true; error = nil; items = []
            do { let result = try await session.search(submitted); try Task.checkCancellation(); items = result }
            catch { if !Task.isCancelled { self.error = error.localizedDescription } }
            if !Task.isCancelled { loading = false }
        }
        .navigationDestination(for: Media.self) { DetailView(original: $0) }
    }
    private func submit() {
        submitted = query.trimmingCharacters(in: .whitespacesAndNewlines)
        revision += 1
    }
}

struct LibraryView: View {
    @EnvironmentObject private var session: LunaSession
    @State private var favorites: [Media] = []
    @State private var records: [Media] = []
    @State private var loading = true
    @State private var error: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("资料库").font(.largeTitle.bold())
                if loading { ProgressView("正在同步…") }
                if !records.isEmpty { Text("继续观看").font(.title2); MediaGrid(items: records) }
                if !favorites.isEmpty { Text("我的收藏").font(.title2); MediaGrid(items: favorites) }
                if let error { EmptyState(title: "资料库暂时不可用", subtitle: error) }
                else if !loading && records.isEmpty && favorites.isEmpty { EmptyState(title: "你的影片会出现在这里", subtitle: "收藏和观看记录会与 LunaTV 同步。", symbol: "books.vertical") }
                Button("刷新资料库") { Task { await load() } }.padding(.vertical, 24)
            }.padding(.horizontal, 64).padding(.top, 24)
        }.task { await load() }
        .navigationDestination(for: Media.self) { DetailView(original: $0) }
    }
    private func load() async {
        loading = true; error = nil
        do { favorites = try await session.library("/api/favorites"); records = try await session.library("/api/playrecords") }
        catch { self.error = error.localizedDescription }; loading = false
    }
}

struct SettingsView: View {
    @EnvironmentObject private var session: LunaSession
    @State private var address = ""
    @AppStorage("native.liveURL") private var liveURL = ""
    @State private var error: String?
    @State private var confirmLogout = false
    var body: some View {
        Form {
            Section("LunaTV 服务器") {
                TextField("服务器地址", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("保存服务器地址") {
                    do { try session.configure(address) } catch { self.error = error.localizedDescription }
                }
            }
            Section("直播") {
                TextField("M3U 订阅地址", text: $liveURL).textInputAutocapitalization(.never).autocorrectionDisabled()
                Text("填写订阅后，前往直播查看频道。").foregroundStyle(.secondary)
            }
            Section("账户") { Button("退出登录", role: .destructive) { confirmLogout = true } }
            Section("关于") {
                LabeledContent("客户端", value: "OrionTV 原生版")
                LabeledContent("版本", value: "1.3.14 · Native 2.1")
                Text("SwiftUI · AVKit").foregroundStyle(.secondary)
            }
            if let error { Text(error).foregroundStyle(.orange) }
        }.navigationTitle("设置").onAppear { address = session.server }
        .confirmationDialog("退出当前账户？", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) { Task { await session.logout() } }
        }
    }
}