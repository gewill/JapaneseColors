# 全项目审计与优化记录

日期：2026-09-12。基线：`c675bbe`。本次修改保留现有平台下限、商品范围、价格和依赖版本。

检查覆盖 21 个 App Swift 文件、3 个抓取脚本、工程/权限/本地化配置、7 个锁定 SPM 包，以及 23 份 JSON、365 张色图和 Asset Catalog 引用。方法包括代码路径检查、Apple/RevenueCat/依赖固定版本源码核对、离线回归、数据基准测试和 macOS 编译。本文区分已验证事实与仍需运行环境验证的项目。

## 已修复的问题

| 范围 | 原行为及触发条件 | 修复 |
|---|---|---|
| `Models/ColorModel.swift` | `ContentView.body` 每次访问列表都读取文件并用 SwiftyJSON 重新解析；倒计时每秒更新根视图 | 按文件缓存解析结果，主线程隔离缓存；已加载资源无需再次读盘/解析 |
| `ContentView.swift` | 秒级 `count` 属于根视图，影响整个列表及详情的依赖 | 倒计时在独立 `TimelineView` 子树更新；自动选色任务每 5 秒触发 |
| 自动切换 | 没有场景生命周期/权益检查；多个活动窗口各自推进共享选择 | 仅在场景活跃、会员有效且未打开根付费页时运行；共享 reservation 保证只有一个窗口推进，取消或关闭后可交接；倒计时也共享 |
| 色卡列表 | 普通 VStack/HStack 会创建当前分类全部卡片，最大分类 63 个 | 使用 LazyVStack/LazyHStack，横向列表明确高度；首次出现或分类改变时定位已选颜色 |
| 恢复状态 | `restoreById()` 对保存日期调用 `.tomorrow`，并强制切换到月份模式 | 直接用保存的 ID 恢复精确颜色，保留合法分类模式；清理无效 ID/分类 |
| 选择一致性 | `@State selectedColor` 与 `@AppStorage selectedColorId` 两份状态易分离；切换分类后旧详情不在新列表，下一色无效 | ID 是唯一选择来源；分类模式与选中色同步；换分类时按需选中首项 |
| 手动选择/程序选色 | 今日/随机走“重复点击即取消”的方法；连续选择同一天会清空详情 | 卡片再次点击保留取消语义；今日、随机、导航使用幂等选择 |
| 日期/随机 | 随机范围终止于 12 月 31 日零点，该日几乎不可能被抽中；按时间秒数抽样受 DST 影响；使用系统日历解析目录日期 | 均匀抽取 1…365 的日期槽位；“今日”明确使用公历，2 月 29 日映射 2 月 28 日 |
| 前后导航 | 文件为空时 `[0]`、`[count-1]`、`[day-1]` 可越界；年/月逻辑分散 | 同一目录导航逻辑安全处理空目录、无选择、跨分类与跨年循环，移除这些无保护下标 |
| `IAPManager.swift` / `JColorsApp.swift` | 多次 onAppear 配置 SDK；启动状态查询额外调用恢复购买；网络失败可能清除会员；自设 24 小时节流忽略权益变化 | 单次 App 初始化；启动只查 CustomerInfo；有效响应才改权限；使用 SDK 缓存和 delegate 接收变化，恢复仅由用户操作触发 |
| `Views/ProView.swift` | 点任意商品却购买 `packages[0]`；不同 offering 可能使用重复 package ID；取消被当作错误；旧错误延迟清除新错误 | 购买当前卡片商品；offering+package 组合身份；正确识别 SKU；区分取消与失败，删除有竞争的错误清除计时器 |
| `Views/FullscreenColorView.swift` | 每次出现添加 NSEvent 监听却不移除；广播通知影响其他窗口；全屏整体点击与内部操作竞争 | 监听绑定 NSView/窗口生命周期并移除，弱引用捕获；只处理所属关键窗口的无修饰箭头，避开输入框/弹窗；退出使用独立背景按钮和辅助功能 Escape |
| 消息容器 | 相同 model ID 或全屏常量作为容器名，多窗口注册互相覆盖 | 每个视图使用生命周期内稳定且唯一的容器名 |
| `Extensions/ColorExtensions.swift` / 色卡 | 原亮度阈值让 112/365 色的小字对比度低于 4.5:1 | 按 sRGB 相对亮度选择黑/白前景，实际 365 色最低 4.585:1；材质上的文字使用系统 primary 前景 |
| 辅助功能 | HEX 仅点击手势，图标缺少说明；tvOS 没有复制却会展示成功消息 | HEX 使用 Button 并补标签/值，增加选色辅助操作；tvOS 保留纯文本，不宣称复制成功；新增简体中文标签 |
| `CardReflectionView.swift` / `LoadingView.swift` | 未尊重 Reduce Motion；反射背景在非活跃场景仍可持续渲染 | 尊重减少动态，非活跃反射速度设为 0；禁用不必要的 3D 拖拽和加载动画；loading 消失时结束动画状态 |
| `Views/MessageView.swift` | 实际编译产生泛型默认参数推断警告，提示未来 Swift 模式会报错 | 默认 Color 背景改用 `where S == Color` 的显式重载，最终源码类型检查无此警告 |
| 隐私/工程 | App 自用 UserDefaults 没有清单；README 声称完全不上传，与 RevenueCat 联网校验不符 | 添加并打包 `PrivacyInfo.xcprivacy`，声明 UserDefaults 的 CA92.1；说明颜色浏览离线、会员服务联网 |
| `scripts/Fetch*.swift` | 忽略 HTTP 状态/网络错误，错误页可能覆盖有效 JSON/JPEG，失败仍 exit 0 | 校验传输错误、2xx、JSON/JPEG 实际载荷；原子写入；错误退出码为 1，目录创建失败明确报错 |

性能依据：[Apple SwiftUI 性能文档](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance)、[WWDC23：Demystify SwiftUI performance](https://developer.apple.com/videos/play/wwdc2023/10160/)、[Apple 延迟加载教程](https://developer.apple.com/tutorials/instruments/reducing-main-thread-work-by-doing-less)。

生命周期依据：[ScenePhase](https://developer.apple.com/documentation/swiftui/scenephase)、[SwiftUI task 的取消与重启](https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:))、[NSEvent 本地监听](https://developer.apple.com/documentation/appkit/nsevent/addlocalmonitorforevents(matching:handler:))、[NSViewRepresentable 清理](https://developer.apple.com/documentation/swiftui/nsviewrepresentable/dismantlensview(_:coordinator:))。

购买依据：[RevenueCat 初始化](https://www.revenuecat.com/docs/getting-started/configuring-sdk)、[恢复必须由用户触发](https://www.revenuecat.com/docs/getting-started/restoring-purchases)、[CustomerInfo 缓存和监听](https://www.revenuecat.com/docs/customers/customer-info)、[锁定 5.31.0 的 Package 身份](https://github.com/RevenueCat/purchases-ios/blob/5.31.0/Sources/Purchasing/Package.swift)。该版本相关 SDK 回调已核实在主线程调度。

渲染/辅助功能依据：[W3C 对比度及 sRGB 公式](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum)、[Apple Material](https://developer.apple.com/documentation/swiftui/material/)、[Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)、[ColorfulX 锁定版本渲染条件](https://github.com/Lakr233/ColorfulX/blob/72101a9f6447c1dd6a44a95d50c875e77e7adada/Sources/ColorfulX/AnimatedMulticolorGradientView.swift)、[OverlayContainer 锁定版本容器注册](https://github.com/fatbobman/SwiftUIOverlayContainer/blob/64a124ba613adc9f2bb7bf00f5a5e8b22a816d14/Sources/SwiftUIOverlayContainer/ContainerManager/ContainerManager.swift)。

隐私/抓取依据：[Apple UserDefaults 使用理由](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)、[App 与 SDK 分别声明数据用途](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests)、[RevenueCat 数据披露](https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-app-privacy)、[锁定 SDK 隐私清单](https://raw.githubusercontent.com/RevenueCat/purchases-ios/5.31.0/Sources/PrivacyInfo.xcprivacy)、[Apple HTTP 响应检查](https://developer.apple.com/documentation/foundation/fetching-website-data-into-memory)。

## 实测结果

| 检查 | 结果 |
|---|---|
| 缓存前 | 同一 Mac、Swift `-O`、SwiftyJSON 5.0.2，绿色分类读取并构造模型 1,000 次：6,295.45 ms，累计构造 63,000 条模型 |
| 缓存后 | 缓存已加载，1,000 次绿色分类查询：0.039708 ms，返回计数 63,000；测试另验证删除已加载文件后仍能读取缓存 |
| 对比度 | 使用实际 SwiftUI Color 对 365 色检查；旧方案最低 1.869:1，新方案最低 4.585:1；黑/白边界及 #A9CB0A 通过 |
| 日期/模型回归 | 365 ID 精确解析；1,460 次正反邻居互逆检查；跨年、2/28→3/1、闰日、无效 ID、365 日期槽位、空/损坏资源通过 |
| 自动切换协调器 | 独占所有权、旧取消不释放新任务、窗口交接、共享倒计时清理断言通过 |
| 购买回归 | 实际 IAPManager 配合 mock SDK，10 项初始化/权益断言通过；包括断网保留、撤权、外部购买、代理时序、重复配置 |
| 抓取脚本 | 3 个脚本 typecheck；URLProtocol 离线桩 12 场景通过：网络错误、HTTP 500、错误 HTML、正常响应；失败不覆盖有效文件 |
| 资源检查 | 新增离线检查脚本通过；重复日期、错误 HEX、分类/月数据差异的反例均能检出 |
| App 编译 | macOS Debug、arm64+x86_64、锁定依赖、关闭签名构建通过；最终修正后增量构建再次通过 |
| 其他静态检查 | 最新完整 App 源码 macOS 13 类型检查通过；iOS/tvOS 条件分支语法解析通过；plutil 和 git diff --check 通过 |

缓存测试比较的是重复数据读取/解析与已缓存查询，不能换算为启动、帧率、整机 CPU 或内存收益。首次使用一个目录仍同步加载该目录一次。没有进行 Instruments 或真机 GPU/内存测量。

原定时器停止写法也进行了独立 Combine 验证：本机取消后剩余 tick 为 0，因此未将“停止必然失效”当作已证实缺陷；本次定时重构依据是根视图秒级更新、场景生命周期和多窗口重复推进。

最终构建仅剩 App Intents 元数据工具提示未链接 AppIntents；项目没有 App Intents 功能，不为消除该提示添加依赖。

## 资源和依赖事实

- 12 月份和 11 分类均覆盖相同的 365 个唯一日期；全部记录逐字段一致，必填字段、HEX、Asset 引用和 JPEG 有效性检查通过。
- 365 张色图全部为 1600×1800 RGB，原文件共 70,969,323 bytes（67.68 MiB）；Assets 内所有文件共 78,308,557 bytes（74.68 MiB）。
- `scripts/images` 的 365 张原图与 Asset 图片逐字节一致，但不在 App Resources 中，因此没有按“App 重复打包”处理。
- iOS 1024 图标虽然格式含 Alpha 通道，实际 Alpha 全为 255，没有发现透明像素问题。
- 7 个锁定依赖的 OS 下限均兼容 iOS/tvOS 16、macOS 13；最高 Swift tools-version 为 5.9。SwiftyJSON 5.0.2 和 RevenueCat 5.31.0 自带隐私清单，已在构建 App 中确认它们和新增 App 清单存在。
- 未升级依赖、转码图片、删除通用工具或更改签名/平台范围。原图体积不是 App 下载体积，后者应按 [Apple 的实际裁剪安装包测量方法](https://developer.apple.com/documentation/xcode/doing-basic-optimization-to-reduce-your-app-s-size) 验证。

## 其余源码覆盖

`Constants.swift`、`CategoryType.swift`、`SwiftyUserDefaults.swift`、`ContainerConfigurationForQueueMessage.swift`、`DateExtensions.swift`、`StringExtensions.swift`、`SKProductExtensions.swift`、`ViewExtensions.swift`、`SwiftUIStyles/ButtonStyle.swift` 和 `Styles.swift` 已检查，未发现具有当前调用证据、需要本轮修改的问题。DateExtensions 中未使用的日期/formatter 工具没有做推测性“优化”。

## 可重复验证

轻量资源检查，无需 Xcode Build、网络或模拟器：

```sh
python3 scripts/ValidateResources.py
```

`VerifyModels.swift` 使用实际 ModelTool 和临时资源 bundle，不启动 App。以下命令接续本次构建目录；若目录已删除，将 SwiftyJSON 源码路径替换为任意已解析的锁定版本 checkout：

```sh
mkdir -p /tmp/jcolors-model-check
xcrun swiftc -swift-version 5 -O -emit-library -emit-module -module-name SwiftyJSON \
  /tmp/jcolors-audit-build/SourcePackages/checkouts/SwiftyJSON/Source/SwiftyJSON/SwiftyJSON.swift \
  -o /tmp/jcolors-model-check/libSwiftyJSON.dylib \
  -emit-module-path /tmp/jcolors-model-check/SwiftyJSON.swiftmodule
xcrun swiftc -swift-version 5 -O -parse-as-library \
  -I /tmp/jcolors-model-check -L /tmp/jcolors-model-check -lSwiftyJSON \
  JColors/Models/ColorModel.swift scripts/VerifyModels.swift \
  -o /tmp/jcolors-model-check/verify
DYLD_LIBRARY_PATH=/tmp/jcolors-model-check /tmp/jcolors-model-check/verify "$PWD"
```

本次构建日志：`/tmp/jcolors-audit-final-build.log`；模型检查：`/tmp/jcolors-audit-baseline/verify-models`；颜色检查：`/tmp/jcolors-view-audit/main.swift`；购买 mock 验证：`/tmp/jcolors-iap-audit/`。临时验证产物不纳入 App。

## 验证边界

- 未运行 iOS/tvOS 完整构建、模拟器或真实设备 UI 自动化；macOS 编译不能证明另外两平台的全部运行行为。
- 未做真实 StoreKit Sandbox 购买、退款和跨设备恢复；mock 验证不能替代交易环境。
- Lazy 列表定位、全屏按钮/手势、键盘窗口切换、VoiceOver、大号 Dynamic Type、Reduce Motion 仍需真实 UI 场景确认；对比度数值检查只覆盖不透明色卡的黑白前景。
- 未读取或修改线上 App Store Connect 隐私标签，也未验证第三方后台配置；本地清单和 README 修正不能替代线上声明核对。
- 资源检查验证结构和一致性，未将 365 段历史典故逐条与原站校勘。
- 审计验证未涉及发版或实际运行抓取脚本下载数据。
