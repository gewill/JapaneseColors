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
  @State var selectedColor: ColorModel?
  @State var fullscreenColor: ColorModel?
  @State var selectedColorId: String = ""
  @State var isAutoChange = false
  @State var count = 5
  @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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

        Toggle("自动随机\(count)秒后", isOn: $isAutoChange)
          .monospacedDigit()
          .onChange(of: isAutoChange, perform: { _ in
            updateTimer()
          })
          .onAppear {
            updateTimer()
          }
          .onReceive(timer) { _ in
            var tmp = (count - 1)
            if tmp == 0 {
              tmp = 5
              setRandomDay()
            }
            count = tmp
          }
          .disabled(isPro == false)
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
              VStack {
                colorListView
              }
              .padding()
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
            HStack {
              colorListView
            }
            .padding()
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
          Button {
            withAnimation(.spring()) {
              fullscreenColor = model
            }
          } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
              .font(.title)
              .rotationEffect(Angle.radians(Double.pi / 2))
              .foregroundColor(Color(hex: model.hex).isLight(threshold: 0.7) == true ? Color.black : Color.white)
              .padding(30)
          }
          .buttonStyle(.plain)
        }
      #endif
    }
  }

  var fullscreenColorView: some View {
    ZStack(alignment: .bottomTrailing) {
      if let model = fullscreenColor {
        Color(hex: model.hex)
        #if os(iOS)
          .statusBarHidden()
          .ignoresSafeArea()
        #endif
          .persistentSystemOverlays(.hidden)
          .onTapGesture {
            withAnimation(.spring()) {
              self.fullscreenColor = nil
            }
          }
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
    if selectedColor?.id == color.id {
      selectedColor = nil
    } else {
      selectedColor = color
      selectedColorId = color.id
    }
  }

  func setToday() {
    guard isPro else {
      showingPro = true
      return
    }

    let date = Date.now
    setColor(date: date)
  }

  func setRandomDay() {
    guard isPro else {
      showingPro = true
      return
    }

    // 非闰年即可
    let date = Date.random(in: Date(integerLiteral: 20230101)! ... Date(integerLiteral: 20231231)!)
    setColor(date: date)
  }

  func setColor(date: Date) {
    let month = date.month
    let day = date.day
    categoryType = .month
    selectedCategory = month.description
    updateColor(ModelTool.shared.getColors(filename: selectedCategory)[day - 1])
  }

  func updateTimer() {
    if isAutoChange {
      timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    } else {
      timer.upstream.connect().cancel()
    }
    count = 5
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
