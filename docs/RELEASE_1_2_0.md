# v1.2.0 — 收藏喜欢的颜色，每天遇见一色

状态：功能已实现，本地回归与三平台编译通过；尚未完成正式签名、真机小组件验收、TestFlight 或发布。

## 功能与边界

| 功能 | 权限 | 行为 |
| --- | --- | --- |
| 收藏 | 免费 | 详情、全屏信息栏与收藏列表可添加/取消；最近收藏在前；本机持久化、同进程多窗口共享 |
| 搜索 | 免费 | 全目录色名、假名、正文、HEX；忽略首尾空白及英文大小写，HEX 可省略 `#`；日期排序；Mac `⌘F` |
| 每日色小组件 | 现有终身会员 | iOS/macOS 独立扩展，小号/中号；纯色、日期、色名、读音、HEX，中号追加典故 |

保留 iOS/tvOS 16、macOS 13 下限。tvOS 不显示收藏、搜索和小组件入口。不新增商品、云同步、账号、推送或行为埋点。

## 实现约定

- `ColorCatalog.shared` 仅解析十二个月份文件一次，保留 `month_day` ID；搜索使用预计算文本索引，不在输入时读盘。
- `FavoritesStore.shared` 在主线程提供所有窗口的唯一状态；UserDefaults 键为 `favoriteColorIDs`，清理无效和重复 ID。
- 收藏、搜索及会员页统一通过根视图呈现。打开期间暂停自动切换，关闭后保留开关偏好并重新等待五秒。
- `jcolors://color/<ID>` 退出全屏、停止自动切换、关闭弹窗，并幂等选择该颜色的月份与详情。关闭弹窗期间连续收到路由时，最后一条有效路由生效。`jcolors://premium` 打开原有会员页；非法 URL 不改变界面状态。
- 时间线预生成七个本地公历日期；以日历运算跨日，2 月 29 日使用 `2_28`；每日申请重载，并在 App 察觉日期/时区变化时请求刷新。系统可能延迟刷新，链接始终使用实际展示条目的 ID。
- App 是权益缓存唯一写入方；首次启动迁移现有会员标记，有效 CustomerInfo 更新共享缓存，仅在状态变化时请求刷新。失败请求不撤销缓存；Widget 没有 RevenueCat、图片或动画依赖。
- iOS App Group 为 `group.org.gewill.JapaneseColors`；macOS 使用兼容 macOS 13 的 `RLK76T8Y89.org.gewill.JapaneseColors`。App 与各自扩展必须签入相同组。

## 可重复的快速回归

推荐执行 `bash scripts/VerifyCore.sh`。脚本定位自身所属仓库，临时编译产物退出时清理；不解析第三方包，不构建 App 或启动模拟器。PR 的 `Core regressions` 工作流运行同一命令，覆盖资源、目录、收藏、搜索、路由与小组件时间线。它不替代 UI、实际跨进程权益或真机签名验收。

在仓库根目录运行：

```sh
python3 scripts/ValidateResources.py
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
  JColors/Models/ColorModel.swift JColors/Models/ColorCatalog.swift \
  JColors/Models/ModelTool.swift JColors/Models/FavoritesStore.swift \
  JColors/Models/AppRoute.swift JColors/Models/AutoChangeCoordinator.swift scripts/VerifyModels.swift -o /tmp/jcolors-verify-models
/tmp/jcolors-verify-models "$PWD"
xcrun swiftc -parse-as-library -swift-version 6 -strict-concurrency=complete \
  JColors/Models/ColorModel.swift JColors/Models/ColorCatalog.swift \
  JColors/Shared/WidgetAccess.swift JColorsWidgets/DailyColorSchedule.swift \
  scripts/VerifyWidgets.swift -o /tmp/jcolors-verify-widgets
/tmp/jcolors-verify-widgets scripts/byMonth
```

覆盖目录完整性、搜索字段及顺序/缓存、收藏去重/恢复/无效存档/通知、URL 校验、公历/跨年/闰日/DST/时区、七天时间线及权益缓存状态迁移。自动切换协调器与 App 使用同一份源码，验证单窗口持有、过期任务不能释放新持有者、多弹窗重叠暂停及重新计算五秒截止时间；该模型检查不替代 SwiftUI 任务取消和真实 UI 倒计时验收。

## 历史验证记录（2026-09-12）

| 验证 | 结果 |
| --- | --- |
| 资源检查与 Swift 6 严格并发回归 | 通过：365 色、目录缓存/搜索/收藏、365 个合法路由与 20 类无效输入、时间线与权益缓存 |
| macOS Debug，arm64/x86_64 | App + macOS Widget 编译通过，下限 13.0 |
| iOS Simulator Debug，arm64 | App + iOS Widget 编译通过，下限 16.0 |
| tvOS Simulator Debug，arm64 | App 编译通过，下限 16.0；产物没有任何 `.appex` |
| Widget 打包 | 仅十二个月份 JSON、隐私声明；无色图、RevenueCat、动画依赖 |
| macOS 26.6.2 实际 App | `⌘F`、HEX 首尾空格/小写、结果定位、搜索无结果、收藏添加/取消/空态、两窗口同步通过 |
| iPhone/iPad iOS 26.5 模拟器实际 App | 搜索、跨月份定位、收藏添加/取消/最近排序、列表选择/关闭、重装后保留通过；修复 iPad 工具栏未显示、iPhone 日期按钮文字裁切 |
| 深链及倒计时 | iPhone 弹窗期间颜色深链、重复点击保持选择通过；实际路由/倒计时代码的独立回归覆盖关闭期间最后一次路由优先、取消后重新等待五秒与多窗口 owner 隔离 |
| Widget 独立渲染 | 小/中尺寸及锁定页、明/暗色文字布局通过；未等同于系统宿主或真机验收 |
| iPhone 模拟器 Widget 系统宿主 | 主屏幕小/中尺寸会员说明显示正常；点击小组件进入现有会员页并显示新增权益；付费态、系统着色及真机签名仍待验证 |

以上构建均使用 `CODE_SIGNING_ALLOWED=NO`，不能作为正式签名有效的证据。首次 tvOS 构建存在原有 AppIcon 品牌资源命名警告；本版未修改图标。AppIntent 元数据提取提示没有 AppIntents 依赖，不影响静态 Widget。

发布查询被本机钥匙串读取阻塞，尚未取得线上版本/构建状态。已终止挂起的只读 ASC 查询；计算机操作工具拒绝访问 SecurityAgent，不能代替用户处理授权。当前本机未找到此 App 的 provisioning profile 或 App Store Distribution 身份，远端 App Group/扩展注册状态仍待核实。

另已实际尝试 iOS 自动签名构建（`-allowProvisioningUpdates`）：Xcode 对 App 与 Widget 均返回 `No Accounts`，选用的通配 `iOS Team Provisioning Profile: *` 不支持 App Groups 或本项目共享组。需先在 Xcode 登录对应开发者账号，配置 App/扩展的显式 Bundle ID 和 App Group profile，再进行设备与分发构建。

## 当前复验（2026-09-28）

- Xcode 27.0（27A266a）暴露 RevenueCat 5.31.0 的 `PaywallColor.init(stringRepresentation:)` 合成初始化方法冲突。按 [上游 #6949](https://github.com/RevenueCat/purchases-ios/pull/6949) 将唯一受影响依赖更新至首个声明修复的 [5.78.0](https://github.com/RevenueCat/purchases-ios/releases/tag/5.78.0)，锁定 `629a56ecef190469914b8f0914bf0446363eb09f`；其他包锁定版本不变。
- 更新后 iOS Simulator、macOS、tvOS Simulator 的 arm64 Debug 构建全部通过；iOS/macOS 包含各自 Widget。均为 `CODE_SIGNING_ALLOWED=NO`，仍不代表设备或分发签名通过。
- PR 核心回归已由 GitHub Actions 执行通过：[运行 36441438656](https://github.com/gewill/JapaneseColors/actions/runs/36441438656)，对应 `e2ea3f0`。工作流与本地使用同一个 `scripts/VerifyCore.sh`。
- ASC 只读查询已恢复；线上 iOS/macOS 仍为 1.1.1，状态 `READY_FOR_DISTRIBUTION`。本机现有有效 Apple Distribution 身份。以上取代历史记录中的钥匙串及无分发身份结论。
- 自动签名前的 Bundle ID 查询仅返回主 App。随后使用 `-allowProvisioningUpdates` 的 iOS Debug 设备构建成功；通过 `codesign -d --entitlements :-` 验证 App 与 iOS Widget 均属于团队 `RLK76T8Y89` 且包含 `group.org.gewill.JapaneseColors`。签名产物已通过 `devicectl` 安装至 iPhone 16 Pro / iOS 27.0；启动因设备锁定被系统拒绝（`FBSOpenApplicationErrorDomain Code 7 / Locked`），真机交互尚未通过。macOS 分发签名、真实权益闭环、TestFlight 和发布仍未完成。
- 使用 AXe 在 iPhone 18 Pro / iOS 27.0 模拟器验证收藏空态、添加后显示及选择返回；截图和操作录像已通过 `gh issue edit --attach` 上传至 #4。搜索的模型回归通过，但本次 AXe 输入未实际进入查询框，不把工具发出事件当作 UI 搜索通过。
- 逐项验收由 [#3](https://github.com/gewill/JapaneseColors/issues/3) 汇总，收藏 #4、搜索 #5、小组件 #6、发布 #7；Xcode 27 兼容修复 #8。

### Mac 补充复验（2026-09-28，065fa6a）

- macOS 27.0 / CUA：⌘F、首尾空格/小写/可选 # 的 HEX、假名、无结果提示、选择返回月份及详情通过。截图与搜索片段已附 #5。
- 无会员状态实际执行：窗口 1 添加收藏，窗口 2 看见并取消，返回原窗口同步更新；详情与全屏均可收藏/取消；⌘Q 退出再启动后收藏列表恢复。截图与操作片段已附 #4。此记录不覆盖 iPad 多窗口。
- 自动签名 macOS arm64 Debug 构建成功；App 与 Widget 的签名 readback 均含 `RLK76T8Y89.org.gewill.JapaneseColors`，`codesign --verify --deep --strict` 成功。此为开发签名，不等于 App Store 分发归档通过。
- 最新核心 CI：[065fa6a / 36443939763](https://github.com/gewill/JapaneseColors/actions/runs/36443939763)。生产自动切换协调器已纳入回归。

### 小组件自动检查补齐（2026-09-28）

- `scripts/VerifyCore.sh` 新增 `VerifyContrast.swift`，直接编译生产 `ColorExtensions.swift`，用 Core Graphics 线性 sRGB 转换独立计算实际前景/背景对比度。365 色全部达到 4.5:1，最低 4.5850:1（9_1）；依据 [WCAG 1.4.3](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum)。仅证明原色模式的色对，不证明系统着色、字体布局或 VoiceOver 阅读顺序。
- 对当前三平台产物检查：iOS/macOS 各一个对应 Widget，扩展资源均为十二个月份 JSON、无 JPG/PNG/Assets.car；链接依赖无 RevenueCat、ColorfulX 或 SwiftUIOverlayContainer。tvOS App 内没有 `.appex`。

## 发布前必须完成

- 注册 App Group，确认 App 与两项扩展的 Bundle ID、证书及 provisioning profile；构建并检查签名内的组一致。
- 在 iPhone/iPad/Mac 系统宿主验证小号和中号小组件、系统着色、文字对比度与点击路由。
- 使用真实沙盒购买/恢复/撤权验证 App 到 Widget 的权益同步，断网后保留最近有效权益。
- 验证升级后的收藏恢复、多窗口同步、冷启动/重复/跨日深链及弹窗期间倒计时暂停。
- 上传 TestFlight，通过设备验收后再提交商店审核。构建号应以远端当前记录为依据，不能仅凭本地默认值判断。

## 商店更新说明草稿

收藏喜欢的颜色，每天遇见一色。

新增免费收藏与全局搜索，按色名、读音、典故或 HEX 找回心仪的颜色。终身会员现可使用小号和中号每日色小组件，点击即可阅读对应典故；已有会员无需再次购买。同时优化目录加载与浏览状态恢复。

## 官方依据

- [WidgetKit 时间线与刷新预算](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)：时间线由系统调度；提前生成条目，不依赖后台常驻计时器。
- [Widget 深链](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity)：通过 `widgetURL` 与 App 的 `onOpenURL` 定位内容。
- [不同小组件位置与外观](https://developer.apple.com/documentation/widgetkit/preparing-widgets-for-additional-contexts-and-appearances)：适配容器背景与系统着色。
- [App Group entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.application-groups) 与 [旧版 macOS App Sandbox 配置](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html)：按目标系统选择组标识格式。
