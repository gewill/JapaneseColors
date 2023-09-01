import Glassfy
import SwiftUI

struct ProView: View {
  @Binding var isPresented: Bool

  @State var skus: [Glassfy.Sku] = []
  @State var permissions: [Glassfy.Permission] = []
  @AppStorage(UserDefaultsKeys.isPro.rawValue) var isPro: Bool = false
  @State var isLoading: Bool = false
  @State var errorMessage: String = ""

  @FocusState private var focus: String?

  // MARK: - life cycle

  var body: some View {
    VStack {
      self.navi
      self.list
    }
  }

  var navi: some View {
    ZStack(alignment: .center) {
      Text("Premium").font(.title)
      HStack {
        Button {
          isPresented = false
        } label: {
          Image(systemName: "xmark")
        }
        Spacer()

        Button {
          self.isLoading = true
          Glassfy.restorePurchases { permissions, error in
            self.showError(message: error?.localizedDescription)
            self.setPermissions(permissions?.all)
            self.isLoading = false
          }
        } label: {
          Text("Restore")
        }
        .disabled(self.isLoading)
      }
      .padding(.horizontal)
    }
    .padding(.vertical)
  }

  var list: some View {
    ZStack(alignment: .center) {
      #if os(tvOS)
      GeometryReader { proxy in
        HStack {
          featuresView
            .frame(width: proxy.size.width / 2)
            .padding()
          proView
        }
      }
      #else
      VStack {
        featuresView
          .padding()
        proView
      }
      #endif
      if self.isLoading {
        ZStack {
          LoadingView(width: 30)
        }
      }
    }
    #if !os(tvOS)
    .frame(minWidth: 300, maxWidth: Constant.maxiPhoneScreenWidth, minHeight: 500)
    #endif
    .onAppear {
      self.updateOfferingsAndPermissions()
    }
  }

  var featuresView: some View {
    Group {
      if self.errorMessage.isEmpty == false {
        Text(self.errorMessage).foregroundColor(.pink)
          .afocusable()
      }

      VStack(alignment: .leading, spacing: Constant.padding) {
        Text("Premium features: ")
          .font(.headline)
        ForEach(ProFeature.allCases) { feature in
          Divider()
          HStack {
            Image(systemName: feature.imageName)
              .symbolRenderingMode(.hierarchical)
              .foregroundColor(Color.accentColor)
            Text(feature.rawValue.localizedStringKey)
          }
        }
      }
      .padding(Constant.padding)
      .background(
        RoundedRectangle(cornerRadius: Constant.cornerRadius, style: .continuous)
          .stroke(Color.separatorColor, lineWidth: 0.5)
      )
      .afocusable()
      .focused($focus, equals: "Pro features")
      .scaleEffect(focus == "Pro features" ? 1.05 : 1)
    }
  }

  var proView: some View {
    Group {
      if self.isPro {
        CardReflectionView {
          VStack(spacing: 20) {
            Text("pro_lifetime")
              .font(.title)
            Text("Thanks for your support!")
          }
          .foregroundColor(.yellow)
        }
        .afocusable()
        .focused($focus, equals: "proView")
        .scaleEffect(focus == "proView" ? 1.05 : 1)
        Spacer()
      } else {
        ScrollView {
          ForEach(skus, id: \.skuId) { sku in
            VStack(spacing: 20) {
              CardReflectionView {
                VStack(spacing: 10) {
                  if sku.productId == IAPManager.Sku.ios_jcolors_pro_lifetime_3.rawValue {
                    Text("pro_lifetime")
                      .font(.title)
                    Text("pro_lifetime_des")
                      .font(.headline)
                  } else {
                    Text(sku.product.localizedTitle)
                      .font(.title)
                    Text(sku.product.localizedDescription)
                      .font(.headline)
                  }
                  Text(sku.product.localizedPrice)
                    .font(.title)
                }
                .foregroundColor(.white)
              }
              .afocusable()
              .focused($focus, equals: sku.skuId)
              .scaleEffect(focus == sku.skuId ? 1.05 : 1)

              Spacer()
              Button {
                self.isLoading = true
                Glassfy.purchase(sku: sku) { transaction, error in
                  self.showError(message: error?.localizedDescription)
                  self.isLoading = false
                  guard let t = transaction, error == nil else {
                    return
                  }
                  self.setPermissions(t.permissions.all)
                }
              } label: {
                Text("Buy Now")
                  .bold()
                  .padding(.horizontal, 20)
                  .padding(.vertical, 6)
              }
              #if !os(tvOS)
              .controlSize(.large)
              #endif
              .buttonStyle(.borderedProminent)
              .clipShape(Capsule())
              .disabled(self.isLoading)
            }
          }
        }
      }
    }
  }

  func updateOfferingsAndPermissions() {
    guard isPro == false else { return }

    isLoading = true
    let group = DispatchGroup()
    group.enter()
    Glassfy.offerings { offers, error in
      self.showError(message: error?.localizedDescription)
      group.leave()
      self.skus = offers?.all.flatMap { $0.skus } ?? []
    }
    group.enter()
    Glassfy.permissions { permissions, error in
      self.showError(message: error?.localizedDescription)
      group.leave()
      self.setPermissions(permissions?.all)
    }
    group.notify(queue: .main) {
      self.isLoading = false
    }
  }

  func updateOfferings() {
    isLoading = true
    Glassfy.offerings { offers, error in
      self.showError(message: error?.localizedDescription)
      self.isLoading = false
      self.skus = offers?.all.flatMap { $0.skus } ?? []
    }
  }

  func updatePermissions() {
    Glassfy.permissions { permissions, error in
      self.showError(message: error?.localizedDescription)
      self.setPermissions(permissions?.all)
    }
  }

  func setPermissions(_ permissions: [Glassfy.Permission]?) {
    if let permissions,
       permissions.contains(where: { $0.isValid && $0.permissionId == IAPManager.Permission.pro_lifetime.rawValue })
    {
      isPro = true
    } else {
      isPro = false
    }

    self.permissions = permissions ?? []
  }

  func showError(message: String?) {
    if let message, message.isEmpty == false {
      errorMessage = message
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.errorMessage = ""
      }
    }
  }
}

struct ProView_Previews: PreviewProvider {
  @State static var isPresented: Bool = true
  static var previews: some View {
    ProView(isPresented: $isPresented)
  }
}
