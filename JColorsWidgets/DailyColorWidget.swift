import SwiftUI
import WidgetKit

struct DailyColorEntry: TimelineEntry {
  let date: Date
  let color: ColorModel?
  let dateLabel: String
  let isPro: Bool

  var url: URL? {
    if isPro, let color { return URL(string: "jcolors://color/\(color.id)") }
    return URL(string: "jcolors://premium")
  }
}

struct DailyColorProvider: TimelineProvider {
  func placeholder(in context: Context) -> DailyColorEntry { previewEntry }

  func getSnapshot(in context: Context, completion: @escaping (DailyColorEntry) -> Void) {
    if context.isPreview {
      completion(previewEntry)
    } else {
      completion(entries(from: Date()).first ?? previewEntry)
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyColorEntry>) -> Void) {
    let now = Date()
    completion(Timeline(entries: entries(from: now), policy: .after(DailyColorSchedule.reloadDate(from: now))))
  }

  private func entries(from now: Date) -> [DailyColorEntry] {
    let isPro = WidgetAccess.isPro
    return DailyColorSchedule.entries(from: now).map {
      DailyColorEntry(date: $0.date, color: $0.color, dateLabel: $0.dateLabel, isPro: isPro)
    }
  }

  private var previewEntry: DailyColorEntry {
    // Gallery and placeholder rendering must not need disk or entitlement access.
    DailyColorEntry(date: Date(timeIntervalSince1970: 1_767_225_600),
                    color: ColorModel(date: "1", desc: "这是一种让人联想到太阳和火焰颜色的带有黄色调的鲜艳红色。由于其鲜明的色彩，它一直被视为神圣的事物。",
                                      hex: "#E34607", kanji: "銀朱", month: "1", ruby: "ぎんしゅ", series: "红色"),
                    dateLabel: "1月1日", isPro: true)
  }
}

struct DailyColorWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.widgetRenderingMode) private var renderingMode
  @Environment(\.showsWidgetContainerBackground) private var showsBackground
  let entry: DailyColorEntry

  private var background: Color {
    if entry.isPro, let color = entry.color { return Color(hex: color.hex) }
    return Color(hex: "F3EEE6")
  }

  private var foreground: Color {
    renderingMode == .fullColor && showsBackground ? background.contrastingForegroundColor : .primary
  }

  var body: some View {
    content
      .foregroundStyle(foreground)
      .padding(16)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .modifier(DailyColorBackground(color: background))
      .widgetURL(entry.url)
  }

  @ViewBuilder
  private var content: some View {
    if entry.isPro, let color = entry.color {
      HStack(alignment: .top, spacing: 18) {
        VStack(alignment: .leading, spacing: 5) {
          Text(entry.dateLabel)
            .font(.caption)
            .widgetAccentable()
          Spacer(minLength: 2)
          Text(color.kanji)
            .font(.system(size: 25, weight: .medium, design: .serif))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
          Text(color.ruby)
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
          Text(color.hex.uppercased())
            .font(.system(.caption2, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if family == .systemMedium {
          Text(color.desc)
            .font(.caption)
            .lineSpacing(3)
            .lineLimit(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
      }
      .accessibilityElement(children: .combine)
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Label("每日一色", systemImage: entry.isPro ? "paintpalette" : "lock")
          .font(.headline)
        Spacer(minLength: 0)
        Text(entry.isPro ? "暂时无法读取颜色" : "每天遇见一色")
          .font(.callout)
        Text(entry.isPro ? "打开 JColors 重试" : "打开 JColors，解锁终身会员小组件")
          .font(.caption)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

private struct DailyColorBackground: ViewModifier {
  let color: Color

  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 17.0, macOS 14.0, *) {
      content.containerBackground(color, for: .widget)
    } else {
      content.background(color)
    }
  }
}

@main
struct DailyColorWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetAccess.kind, provider: DailyColorProvider()) { entry in
      DailyColorWidgetView(entry: entry)
    }
    .configurationDisplayName("每日一色")
    .description("每天欣赏一种日本传统色。终身会员专享。")
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
}
