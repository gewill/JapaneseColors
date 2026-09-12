//
//  ContentView.swift
//  JColors
//
//  Created by will on 17/08/2023.
//

import SwiftUI
import SwiftUIOverlayContainer

struct ContentView: View {
  @State var mode: NavigationSplitViewVisibility = .all

  @AppStorage("categoryType") var categoryType: CategoryType = .color
  @AppStorage("selectedCategory") var selectedCategory: String = "yellow"
  @AppStorage(UserDefaultsKeys.isFullscreenColor.rawValue) var isFullscreenColor: Bool = false
  @AppStorage(UserDefaultsKeys.selectedColorId.rawValue) var selectedColorId: String = ""
  @AppStorage(UserDefaultsKeys.isAutoChange.rawValue) var isAutoChange = false
  @AppStorage(UserDefaultsKeys.autoChangeType.rawValue) var autoChangeType: AutoChangeType = .order
  @Environment(\.scenePhase) private var scenePhase
  @State private var playbackID = UUID()
  @ObservedObject private var playback = AutoChangeCoordinator.shared

  var selectedColor: ColorModel? {
    ModelTool.shared.color(id: selectedColorId)
  }

  var shouldAutoChange: Bool {
    isAutoChange && isPro && scenePhase == .active && !showingPro
      && (playback.owner == nil || playback.owner?.viewID == playbackID)
  }

  let colorWidth: CGFloat = {
    switch UserInterfaceIdiom.current {
    case .mac, .pad:
      return 300
    case .phone:
      return 200
    case .tv:
      return 400
    default:
      return 300
    }
  }()

  @AppStorage(UserDefaultsKeys.isPro.rawValue) var isPro: Bool = false
  @State private var showingPro = false

  // MARK: - life cycle

  var body: some View {
    ZStack {
      switch UserInterfaceIdiom.current {
      case .mac, .pad:
        splitView
      case .tv:
        HStack {
          ScrollView {
            slideView
          }
          .frame(width: 300)

          colorListAndDetailView
        }
      default:
        NavigationStack {
          ScrollView {
            VStack {
              slideView
              colorListAndDetailView
            }
          }
          .navigationTitle("日本传统色")
          #if os(iOS)
            .toolbar {
              ToolbarItemGroup(placement: .navigationBarTrailing) {
                datesView
              }
            }
          #endif
        }
      }
      fullscreenColorView
    }
    .onAppear {
      restoreSelection()
    }
    .onChange(of: categoryType) { _ in
      alignCategoryWithSelection()
    }
    .onChange(of: selectedCategory) { _ in
      selectCategoryIfNeeded()
    }
    .task(id: shouldAutoChange) {
      guard shouldAutoChange, let reservation = playback.acquire(for: playbackID) else {
        return
      }
      defer { playback.release(reservation) }
      while !Task.isCancelled {
        playback.scheduleNextChange(for: reservation)
        do {
          try await Task.sleep(nanoseconds: 5_000_000_000)
        } catch {
          return
        }
        guard !Task.isCancelled, shouldAutoChange else { return }
        switch autoChangeType {
        case .order:
          nextColor()
        case .random:
          setRandomDay()
        }
      }
    }
  }

  var splitView: some View {
    NavigationSplitView(columnVisibility: $mode) {
      slideView
        .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 300)
      #if !os(macOS)
        .navigationTitle("日本传统色")
      #endif
    } detail: {
      colorListAndDetailView
    }
    #if os(macOS)
    .navigationTitle("日本传统色")
    #endif
  }

  var datesView: some View {
    Group {
      Button {
        showingPro = true
      } label: {
        Label("Premium", systemImage: "crown")
          .foregroundColor(isPro ? .yellow : .accentColor)
      }
      Button {
        setToday()
      } label: {
        Text("今天")
      }

      Button {
        setRandomDay()
      } label: {
        Text("随机")
      }
    }
    .buttonStyle(.bordered)
    .clipShape(Capsule())
    .sheet(isPresented: $showingPro) {
      ProView(isPresented: $showingPro)
    }
  }

  var slideView: some View {
    VStack(alignment: .center, spacing: Constant.padding) {
      Group {
        if UserInterfaceIdiom.current != .phone {
          datesView
        }
        let layout = UserInterfaceIdiom.current == .phone ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
        layout {
          Picker("自动切换方式", selection: $autoChangeType) {
            ForEach(AutoChangeType.allCases) {
              Text($0.rawValue.localizedStringKey)
            }
          }
          AutoChangeToggle(isOn: $isAutoChange, nextChangeDate: playback.nextChangeDate)
            .disabled(isPro == false)
        }
        .padding(Constant.padding)
        .background(Material.regular)
        .cornerRadius(Constant.cornerRadius)

        Picker("Category Type", selection: $categoryType) {
          ForEach(CategoryType.allCases) { type in
            Text(type.rawValue.localizedStringKey).id(type)
          }
        }
        .pickerStyle(.segmented)
      }
      .padding(.horizontal)

      switch UserInterfaceIdiom.current {
      case .mac, .pad, .tv:
        ScrollView {
          VStack(spacing: 10) {
            categoryView
            Divider()
          }
        }
        .buttonStyle(PrimaryButtonStyle())
      default:
        ScrollView(.horizontal) {
          HStack(spacing: 10) {
            categoryView
          }
          .padding()
        }
        .buttonStyle(PrimaryButtonStyle())
      }
    }
  }

  var categoryView: some View {
    Group {
      if categoryType == .color {
        ForEach(ColorCategory.allCases) { series in
          let isSelected = selectedCategory == series.rawValue
          Button {
            selectedCategory = "\(series.rawValue)"
          } label: {
            HStack {
              ZStack {
                Circle()
                  .fill(series.color)
                  .frame(width: 30, height: 30)
                if isSelected {
                  Circle()
                    .fill(series.color)
                    .colorInvert()
                    .frame(width: 10, height: 10)
                }
              }
              Text(series.rawValue.localizedStringKey)
                .font(.headline)
                .foregroundColor(isSelected ? Color.accentColor : Color.gray)
            }
          }
          .padding(6)
          .background(Material.ultraThinMaterial)
          .cornerRadius(30)
        }
      } else {
        ForEach(1 ..< 13) { month in
          let isSelected = selectedCategory == "\(month)"
          Button {
            selectedCategory = "\(month)"
          } label: {
            Text("\(month)月")
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .foregroundColor(isSelected ? Color.accentColor : Color.gray)
              .font(.headline)
          }
          .padding(6)
          .background(Material.ultraThinMaterial)
          .cornerRadius(30)
        }
      }
    }
  }

  var colorListAndDetailView: some View {
    Group {
      switch UserInterfaceIdiom.current {
      case .mac, .pad, .tv:
        HStack {
          ScrollViewReader { reader in
            ScrollView {
              LazyVStack {
                colorListView
              }
              .padding()
            }
            .task(id: selectedCategory) {
              reader.scrollTo(selectedColorId, anchor: .center)
            }
            .onChange(of: selectedColorId) { newValue in
              reader.scrollTo(newValue, anchor: .center)
            }
          }
          detailView
        }
      default:
        ScrollViewReader { reader in
          ScrollView(.horizontal) {
            LazyHStack {
              colorListView
            }
            .padding()
          }
          .frame(height: colorWidth + 52)
          .task(id: selectedCategory) {
            reader.scrollTo(selectedColorId, anchor: .center)
          }
          .onChange(of: selectedColorId) { newValue in
            reader.scrollTo(newValue, anchor: .center)
          }
        }
        detailView
      }
    }
  }

  var colorListView: some View {
    ForEach(ModelTool.shared.getColors(filename: selectedCategory)) { model in
      #if os(tvOS)
        Button {
          updateColor(model)
        } label: {
          ColorCard(model: model)
        }
        .buttonStyle(.card)
      #else
        ZStack(alignment: .bottomTrailing) {
          ColorCard(model: model)
            .id(model.id)
            .onTapGesture {
              updateColor(model)
            }
            .accessibilityAction(named: Text("选择颜色")) {
              updateColor(model)
            }
          Button {
            selectedColorId = model.id
            withAnimation(.spring()) {
              isFullscreenColor = true
            }
          } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
              .font(.title)
              .rotationEffect(Angle.radians(Double.pi / 2))
              .foregroundColor(Color(hex: model.hex).contrastingForegroundColor)
              .padding(30)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("全屏显示颜色")
        }
      #endif
    }
  }

  var fullscreenColorView: some View {
    ZStack(alignment: .bottomTrailing) {
      if isFullscreenColor,
         let model = selectedColor
      {
        FullscreenColorView(
          model: model,
          didSwipeLeft: {
            previousColor()
          }, didSwipeRight: {
            nextColor()
          }, onDismiss: {
            withAnimation(.spring()) {
              isFullscreenColor = false
            }
          })
      }
    }
  }

  var detailView: some View {
    ScrollView {
      if let selectedColor {
        VStack {
          Image(selectedColor.id)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .cornerRadius(30)
            .padding(10)
            .background(Material.ultraThinMaterial)
            .cornerRadius(40)
            .frame(maxWidth: 700)
          #if os(tvOS)
            .focusable()
          #endif
          Text(selectedColor.desc)
          #if os(tvOS)
            .focusable()
          #endif
        }
        .padding()
      } else {
        introView
      }
    }
    .frame(maxWidth: .infinity)
  }

  var introView: some View {
    VStack {
      Image("index")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .cornerRadius(30)
        .padding(10)
        .background(Material.ultraThinMaterial)
        .cornerRadius(40)
        .frame(maxWidth: 700)
      #if os(tvOS)
        .focusable()
      #endif
      Text("""
      日本人自古以来便擅于从各种日常之中获得色彩的灵感，并以纤细的视角赋予各种色彩独一无二的地位，并更进一步应用于绘画、工艺、织染甚至于文学与诗歌上。

      于是我们可以从平安时代的女性们身上，看见和服的典雅配色；从日式庭园中，一窥白山绿水的调和色彩；在千年古城的堂奥里，看见代表昔日风华的金灿色泽。

      「日本传统色」便是在长远的历史中一路累积而来。这里罗列了 365 种颜色，可以看到每种颜色背后的典故。

      颜色数据均来源于 [暦生活](https://www.543life.com/)

      **授权自limboy的网页版https://colors.limboy.me/**
      """)
      #if os(tvOS)
      .focusable()
      #endif
    }
    .padding()
  }

  // MARK: - private methods

  func updateColor(_ color: ColorModel) {
    selectedColorId = selectedColorId == color.id ? "" : color.id
  }

  func selectColor(_ color: ColorModel) {
    selectedColorId = color.id
    selectedCategory = categoryType == .month
      ? color.month
      : ModelTool.shared.colorCategory(for: color) ?? selectedCategory
  }

  func nextColor() {
    if let color = ModelTool.shared.adjacentColor(to: selectedColorId, in: selectedCategory, forward: true) {
      selectColor(color)
    }
  }

  func previousColor() {
    if let color = ModelTool.shared.adjacentColor(to: selectedColorId, in: selectedCategory, forward: false) {
      selectColor(color)
    }
  }

  func setToday() {
    guard isPro else {
      showingPro = true
      return
    }
    if let color = ModelTool.shared.color(on: .now) {
      categoryType = .month
      selectColor(color)
    }
  }

  func setRandomDay() {
    guard isPro else {
      showingPro = true
      return
    }
    if let color = ModelTool.shared.randomColor() {
      categoryType = .month
      selectColor(color)
    }
  }

  func alignCategoryWithSelection() {
    if let color = selectedColor {
      selectColor(color)
    } else {
      selectedCategory = categoryType == .month ? "1" : ColorCategory.yellow.rawValue
    }
  }

  func selectCategoryIfNeeded() {
    let colors = ModelTool.shared.getColors(filename: selectedCategory)
    if !selectedColorId.isEmpty && !colors.contains(where: { $0.id == selectedColorId }) {
      selectedColorId = colors.first?.id ?? ""
    }
  }

  func restoreSelection() {
    // Resolve the persisted ID directly; restoring must neither advance nor toggle it.
    if selectedColor != nil {
      alignCategoryWithSelection()
    } else {
      selectedColorId = ""
      isFullscreenColor = false
      let isValidCategory = categoryType == .month
        ? ModelTool.shared.allMonths.contains { String($0) == selectedCategory }
        : ColorCategory(rawValue: selectedCategory) != nil
      if !isValidCategory {
        alignCategoryWithSelection()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

// Only this small subtree refreshes each second; the catalog and detail do not.
private struct AutoChangeToggle: View {
  @Binding var isOn: Bool
  let nextChangeDate: Date?

  var body: some View {
    if let nextChangeDate {
      TimelineView(.periodic(from: .now, by: 1)) { context in
        let seconds = max(1, min(5, Int(ceil(nextChangeDate.timeIntervalSince(context.date)))))
        Toggle("自动切换\(seconds)秒后", isOn: $isOn)
          .monospacedDigit()
      }
    } else {
      Toggle("自动切换\(5)秒后", isOn: $isOn)
        .monospacedDigit()
    }
  }
}

// Selection and playback preferences are shared by WindowGroup instances.
// A single reservation prevents multiple active windows from advancing them twice.
@MainActor
private final class AutoChangeCoordinator: ObservableObject {
  struct Reservation: Equatable {
    let viewID: UUID
    let token = UUID()
  }

  static let shared = AutoChangeCoordinator()
  @Published private(set) var owner: Reservation?
  @Published private(set) var nextChangeDate: Date?

  func acquire(for viewID: UUID) -> Reservation? {
    guard owner == nil || owner?.viewID == viewID else { return nil }
    let reservation = Reservation(viewID: viewID)
    owner = reservation
    return reservation
  }

  func scheduleNextChange(for reservation: Reservation) {
    if owner == reservation {
      nextChangeDate = Date.now.addingTimeInterval(5)
    }
  }

  func release(_ reservation: Reservation) {
    if owner == reservation {
      owner = nil
      nextChangeDate = nil
    }
  }
}
