import SwiftUI

#if !os(tvOS)
struct FavoriteButton: View {
  let color: ColorModel
  @ObservedObject private var favorites = FavoritesStore.shared

  var body: some View {
    let isFavorite = favorites.contains(id: color.id)
    Button {
      favorites.toggle(id: color.id)
    } label: {
      Image(systemName: isFavorite ? "heart.fill" : "heart")
        .frame(minWidth: 44, minHeight: 44)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(isFavorite ? Text("Remove from favorites") : Text("Add to favorites"))
    .accessibilityValue(Text(color.kanji))
    .accessibilityIdentifier("favorite-\(color.id)")
    .help(isFavorite ? Text("Remove from favorites") : Text("Add to favorites"))
  }
}
#endif
