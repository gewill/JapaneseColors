import RevenueCat
import SwiftUI

struct ProView: View {
  @Binding var isPresented: Bool

  @State var packages: [RevenueCat.Package] = []
  @State var entitlementInfos: [String: RevenueCat.EntitlementInfo] = [:]
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
          Purchases.shared.restorePurchases { customerInfo, error in
            self.isLoading = false
            self.showError(message: error?.localizedDescription)
            self.setEntitlementInfos(customerInfo?.entitlements.all)
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
          ForEach(packages) { package in
            VStack(spacing: 20) {
              CardReflectionView {
                VStack(spacing: 10) {
                  if package.identifier == IAPManager.Sku.ios_jcolors_pro_lifetime_3.rawValue {
                    Text("pro_lifetime")
                      .font(.title)
                    Text("pro_lifetime_des")
                      .font(.headline)
                  } else {
                    Text(package.storeProduct.localizedTitle)
                      .font(.title)
                    Text(package.storeProduct.localizedDescription)
                      .font(.headline)
                  }
                  Text(package.localizedPriceString)
                    .font(.title)
                }
                .foregroundColor(.white)
              }
              .afocusable()
              .focused($focus, equals: package.identifier)
              .scaleEffect(focus == package.identifier ? 1.05 : 1)

              Spacer()
              Button {
                self.isLoading = true
                Purchases.shared.purchase(package: packages[0]) { _, customerInfo, error, _ in
                  self.isLoading = false
                  self.showError(message: error?.localizedDescription)
                  self.setEntitlementInfos(customerInfo?.entitlements.all)
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
    Purchases.shared.getOfferings { offerings, error in
      self.showError(message: error?.localizedDescription)
      group.leave()
      self.packages = offerings?.all.flatMap { $0.value.availablePackages } ?? []
    }
    group.enter()
    Purchases.shared.getCustomerInfo { customerInfo, error in
      self.showError(message: error?.localizedDescription)
      group.leave()
      self.setEntitlementInfos(customerInfo?.entitlements.all)
    }
    group.notify(queue: .main) {
      self.isLoading = false
    }
  }

  func updateOfferings() {
    isLoading = true
    Purchases.shared.getOfferings { offerings, error in
      self.showError(message: error?.localizedDescription)
      self.isLoading = false
      self.packages = offerings?.all.flatMap { $0.value.availablePackages } ?? []
    }
  }

  func updatePermissions() {
    Purchases.shared.getCustomerInfo { customerInfo, _ in
      self.setEntitlementInfos(customerInfo?.entitlements.all)
    }
  }

  func setEntitlementInfos(_ entitlementInfos: [String: RevenueCat.EntitlementInfo]?) {
    if let entitlementInfos,
       let pro = entitlementInfos[IAPManager.Permission.pro_lifetime.rawValue],
       pro.isActive
    {
      isPro = true
    } else {
      isPro = false
    }

    self.entitlementInfos = entitlementInfos ?? [:]
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
