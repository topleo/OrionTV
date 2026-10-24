# OrionTV 原生 Apple TV 客户端

独立的 SwiftUI / AVKit tvOS 应用，不加载 React Native、Expo、Hermes 或网页。需要 tvOS 18 或更高版本。

- 系统 `TabView` 的 `sidebarAdaptable` 样式提供左侧一级导航：搜索、热门剧集、电影、电视剧、综艺、Top 250、资料库、直播、设置。每个分区使用 `NavigationStack` 管理详情与返回。
- tvOS 27 的侧栏底部提供当前分类的细分筛选；较早系统的筛选随页面标题一起滚动。内容区域没有固定顶栏。
- 选集使用相同宽高的原生按钮、等宽数字与固定间距，避免不同位数的集数造成大小不一。
- 海报使用统一尺寸、固定标题空间与原生卡片焦点效果；整行 `focusSection` 为未填满的末行提供方向导航范围。接近列表末尾自动加载下一页，并按原始页长推进游标、去重和停止重复页。
- `URLSession` 连接现有 LunaTV；收藏和播放记录与后端同步。登录会话存入 Keychain，不保存密码、不读取旧客户端保存的凭据。
- `AVPlayerViewController` 提供系统播放、暂停、拖动和字幕/音轨控件；支持选集、自动下一集、续播、定期保存进度。
- 直播支持用户提供的 HTTP(S) M3U 订阅。未配置、无频道或加载失败时提供设置与返回入口，保持原生侧栏可返回。侧栏项目固定；影视源影响搜索/详情，M3U 影响频道列表。

现有 React Native 客户端保持独立。原生版的核心流程已实现；RN 中的跳过片头片尾、自定义广告过滤及远程输入服务尚未移植。播放来源不可用时，可在详情页切换其他来源。

## 构建与安装

可直接打开 `OrionTVNative.xcodeproj`，选择自己的 bundle identifier 和签名 Team，再运行到 Apple TV。工程只引用本目录中的 Swift 文件和资源，无 Node、CocoaPods 或第三方运行库依赖。

也可使用 Xcode 命令行工具生成未签名包，然后交给自己的签名服务器：

```sh
python3 build.py --output build --bundle-id com.example.oriontv --server http://your-server:3000
```

`--server` 仅给本地生成的安装包填入默认地址，默认留空并由用户在电视上输入。可用 `--live-url https://example.com/channels.m3u` 给安装包配置初始直播订阅；仅在设备尚无订阅时写入，每个默认地址只应用一次，用户以后可清空或更换。`build/` 不提交 Git。个人签名证书、Apple ID、服务器密码和授权会话不能提交仓库。

在不允许编译器插件建立嵌套沙箱的构建宿主中，可增加 `--disable-plugin-sandbox`；正常 Xcode 构建不需要该参数。它仅控制 Apple Swift 编译器的插件子进程设置。

Apple Silicon Mac 可用 `--simulator` 生成模拟器 `.app`，例如 `--output /tmp/orion-preview --simulator`。

如需重新生成 Xcode 工程，安装 Ruby `xcodeproj` 后运行 `ruby generate-project.rb`。生成器不会修改 Expo 的工程。

## 验证

```sh
swiftc Sources/Models.swift Tests/CoreTests.swift -o /tmp/orion-core-tests
/tmp/orion-core-tests
```

模型测试覆盖数字 ID、收藏/记录 key、集数转换、进度请求体、M3U 去重和相对地址，以及统一卡片尺寸、不完整末行索引、分页游标、去重和终止条件。第一版 Apple TV 4K 真机已确认登录、导航和播放正常；新版侧栏与网格已在 tvOS 27 模拟器执行遥控器回归测试，真机需要重新确认。收藏同步、各种来源的字幕/音轨、M3U 频道及长时间连续播放仍需按实际内容验证；不能用编译通过代替遥控器检查。

可重复运行的界面回归使用本地虚构片单，无需账户，也不访问生产服务器。覆盖第一行第 6 张向下到不足一行的第 9 张、返回键先回到顶部、再次返回打开侧栏，以及连续下移自动加载到第 43 张、未设置直播/空订阅/无效地址时返回侧栏及进入设置。需要 Xcode、Ruby `xcodeproj` 和已安装的 1080p Apple TV 模拟器；所有测试生成物放在仓库外：

```sh
python3 Tests/UI/fixture.py
# 另一个终端；保持上面的测试服务器运行
ruby Tests/UI/generate.rb /tmp/orion-ui-validation-project
xcodebuild test -project /tmp/orion-ui-validation-project/Validation.xcodeproj -scheme Validation -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath /tmp/orion-ui-validation-build
```

## 与上游同步

保留 `upstream=https://github.com/orion-lib/OrionTV`。先在新分支合并上游，再验证原生客户端使用的接口和播放行为。原生代码隔离于 `native/tvos`，通常不会与上游 React Native 页面冲突。上游新增的 JavaScript 界面功能仍需用 Swift 实现，不能通过合并自动变成原生界面。

原生实现沿用仓库许可，保留原项目与资产来源。
