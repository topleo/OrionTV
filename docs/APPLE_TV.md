# Apple TV 版本

此 fork 基于 orion-lib/OrionTV，保留 React Native TVOS / Expo 51 和现有播放、收藏、续播逻辑。tvOS 浏览界面采用系统字体、白色焦点反馈、海报视差、更大的文字和电视安全边距。Android 沿用原来的组件。

设计参考 [Apple Design Skill](https://github.com/dickwu/apple-design-skill) 和 [Apple tvOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos)。这是一套 tvOS 风格的 React Native 界面，并非改写为 SwiftUI。

## 本地构建

安装 Xcode（含 tvOS 平台）、Node 20、Yarn 1 和 CocoaPods。项目使用 Expo 51，因此需保留仓库的依赖版本。

在被 Git 忽略的 `.env.local` 中设置自己的值：

```dotenv
ORION_BUNDLE_IDENTIFIER=com.example.oriontv
EXPO_PUBLIC_LUNATV_SERVER=http://your-server:3000
```

服务地址也可在应用设置中填写。不要将 Apple ID、密码、证书、私钥或描述文件提交到仓库。

```sh
yarn install
EXPO_TV=1 npx expo prebuild --platform ios --no-install
cd ios
pod install
open OrionTV.xcworkspace
```

在 Xcode 为 OrionTV 选择自己的签名 Team 和 Apple TV 真机。免费 Apple ID 的描述文件有时限，安装不等于已配置自动续签。

`plugins/withTVSceneLifecycle.js` 在 prebuild 时生成 SceneDelegate 和场景配置，避免使用新 SDK 构建后在 tvOS 27 因缺少场景生命周期而启动崩溃。不要只修改被忽略的 `ios/` 文件。该插件适配 Expo 51 的 Objective-C AppDelegate；升级 Expo 时需要检查模板兼容性。

## 合并上游更新

```sh
git remote add upstream https://github.com/orion-lib/OrionTV.git # 已存在时无需再次添加
git fetch upstream
git switch -c merge/upstream-update
git merge upstream/master
```

解决冲突后验证 tvOS prebuild、Release 构建和真机播放，再把分支合并到此 fork。平台兼容修复和界面改动分为独立提交，方便定位冲突。此仓库不保存个人签名配置，也不自动合并未经验证的上游更新。

## 验证范围

已验证干净 prebuild 和再次 prebuild 都只生成一份 SceneDelegate；应用代码 TypeScript 检查通过。上游 `utils/__tests__/DeviceUtils.test.ts` 的旧尺寸 mock 缺少 `scale` / `fontScale`，完整 `tsc --noEmit` 仍报告这些既有错误。

真机还应检查遥控器焦点、搜索输入、收藏、继续观看、播放和系统“减少动态效果”。代码检查无法替代电视上的视觉和交互检查。

在 Apple TV 4K 真机上已确认安装、播放和首页海报区向上返回顶部导航。焦点修复同时保留返回键恢复导航的路径，并通过遥控器事件行为检查。
