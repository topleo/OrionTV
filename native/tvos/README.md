# OrionTV 原生 Apple TV 客户端

独立的 SwiftUI / AVKit tvOS 应用，不加载 React Native、Expo、Hermes 或网页。需要 tvOS 17 或更高版本。

- 系统 `TabView` 提供现在观看、资料库、搜索、直播、设置；每个分区使用 `NavigationStack` 管理详情与返回，避免自行拦截遥控器焦点事件。
- 首页只有一行分类/标签 `Picker`。影片海报使用原生卡片焦点效果。
- `URLSession` 连接现有 LunaTV；收藏和播放记录与后端同步。登录会话存入 Keychain，不保存密码、不读取旧客户端保存的凭据。
- `AVPlayerViewController` 提供系统播放、暂停、拖动和字幕/音轨控件；支持选集、自动下一集、续播、定期保存进度。
- 直播支持用户提供的 HTTP(S) M3U 订阅。

现有 React Native 客户端保持独立。原生版的核心流程已实现；RN 中的跳过片头片尾、自定义广告过滤及远程输入服务尚未移植。播放来源不可用时，可在详情页切换其他来源。

## 构建与安装

可直接打开 `OrionTVNative.xcodeproj`，选择自己的 bundle identifier 和签名 Team，再运行到 Apple TV。工程只引用本目录中的 Swift 文件和资源，无 Node、CocoaPods 或第三方运行库依赖。

也可使用 Xcode 命令行工具生成未签名包，然后交给自己的签名服务器：

```sh
python3 build.py --output build --bundle-id com.example.oriontv --server http://your-server:3000
```

`--server` 仅给本地生成的安装包填入默认地址，默认留空并由用户在电视上输入。`build/` 不提交 Git。个人签名证书、Apple ID、服务器密码和授权会话不能提交仓库。

在不允许编译器插件建立嵌套沙箱的构建宿主中，可增加 `--disable-plugin-sandbox`；正常 Xcode 构建不需要该参数。它仅控制 Apple Swift 编译器的插件子进程设置。

如需重新生成 Xcode 工程，安装 Ruby `xcodeproj` 后运行 `ruby generate-project.rb`。生成器不会修改 Expo 的工程。

## 验证

```sh
swiftc Sources/Models.swift Tests/CoreTests.swift -o /tmp/orion-core-tests
/tmp/orion-core-tests
```

模型测试覆盖数字 ID、收藏/记录 key、集数转换、进度请求体、M3U 去重和相对地址。Apple TV 4K 真机已确认登录、顶部导航和播放正常。收藏同步、各种来源的字幕/音轨、M3U 频道及长时间连续播放仍需按实际内容验证；不能用编译通过代替遥控器检查。

## 与上游同步

保留 `upstream=https://github.com/orion-lib/OrionTV`。先在新分支合并上游，再验证原生客户端使用的接口和播放行为。原生代码隔离于 `native/tvos`，通常不会与上游 React Native 页面冲突。上游新增的 JavaScript 界面功能仍需用 Swift 实现，不能通过合并自动变成原生界面。

原生实现沿用仓库许可，保留原项目与资产来源。
