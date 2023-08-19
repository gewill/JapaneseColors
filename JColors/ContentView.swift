//
//  ContentView.swift
//  JColors
//
//  Created by will on 17/08/2023.
//

import SwiftUI

struct ContentView: View {
  @State var mode: NavigationSplitViewVisibility = .all

  @AppStorage("categoryType") var categoryType: CategoryType = .color
  @AppStorage("selectedCategory") var selectedCategory: String = "yellow"
  @State var selectedColor: ColorModel?

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

  // MARK: - life cycle

  var body: some View {
    switch UserInterfaceIdiom.current {
    case .mac, .pad:
      splitView
    default:
      ScrollView {
        VStack {
          slideView
          colorListAndDetailView
        }
      }
    }
  }

  var splitView: some View {
    NavigationSplitView(columnVisibility: $mode) {
      slideView
        .navigationSplitViewColumnWidth(min: 100, ideal: 150, max: 200)
    } detail: {
      colorListAndDetailView
    }
    .navigationTitle("日本传统色")
  }

  var slideView: some View {
    VStack(alignment: .center) {
      Picker("Category Type", selection: $categoryType) {
        ForEach(CategoryType.allCases) { type in
          Text(type.rawValue.localizedStringKey).id(type)
        }
      }
      .pickerStyle(.segmented)
      .padding()
      switch UserInterfaceIdiom.current {
      case .mac, .pad:
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
    .background(Material.ultraThinMaterial)
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
                .foregroundColor(isSelected ? Color.accentColor : Color.primary)
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
              .foregroundColor(isSelected ? Color.accentColor : Color.primary)
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
      case .mac, .pad:
        HStack {
          ScrollView {
            VStack {
              colorListView
            }
            .padding()
          }
          detailView
        }
      default:
        ScrollView(.horizontal) {
          HStack {
            colorListView
          }
          .padding()
        }
        detailView
      }
    }
  }

  var colorListView: some View {
    ForEach(ModelTool.shared.getColors(filename: selectedCategory)) { model in
      VStack {
        HStack {
          Text("\(model.month).\(model.date)")
            .font(.title3)
          Spacer()

          Text(model.hex)
            .onTapGesture {
              #if os(tvOS)
              #elseif os(iOS)
                UIPasteboard.general.string = model.hex
              #else
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(model.hex, forType: .string)
              #endif
            }
        }
        .monospacedDigit()
        Spacer()
        Text(model.kanji)
          .font(.title)
        Text(model.ruby)
          .font(.title2)
        Spacer()
      }
      .padding(20)
      .foregroundColor(Color(hex: model.hex))
      .colorInvert()
      #if os(tvOS)
        .frame(width: 400, height: 400)
      #else
        .frame(width: UserInterfaceIdiom.current == .phone ? 200 : 300, height: UserInterfaceIdiom.current == .phone ? 200 : 300)
      #endif
        .background(Color(hex: model.hex))
        .cornerRadius(30)
        .padding(10)
        .background(Material.ultraThinMaterial)
        .cornerRadius(40)
        .onTapGesture {
          selectedColor = model
        }
    }
  }

  var detailView: some View {
    Group {
      if let selectedColor {
        ScrollView {
          VStack {
            Image(selectedColor.id)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .cornerRadius(30)
              .padding(10)
              .background(Material.ultraThinMaterial)
              .cornerRadius(40)
              .padding()
            Text(selectedColor.desc)
              .padding()
          }
        }
      } else {
        Spacer()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
