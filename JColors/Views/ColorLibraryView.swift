import SwiftUI

#if !os(tvOS)
struct ColorLibraryView: View {
  enum Mode {
    case favorites, search
  }

  let mode: Mode
  let onSelect: (ColorModel) -> Void
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var favorites = FavoritesStore.shared
  @State private var query = ""

  private var results: [ColorModel] {
    mode == .favorites ? favorites.colors : ColorCatalog.shared.search(query: query)
  }

  var body: some View {
    NavigationStack {
      Group {
        if mode == .search {
          #if os(macOS)
          content.searchable(text: $query, placement: .toolbar, prompt: "Name, reading, story or HEX")
          #else
          content.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name, reading, story or HEX")
          #endif
        } else {
          content
        }
      }
      .navigationTitle(mode == .favorites ? Text("Favorites") : Text("Search colors"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
            .keyboardShortcut(.cancelAction)
        }
      }
    }
    #if os(macOS)
    .frame(minWidth: 380, idealWidth: 520, minHeight: 420, idealHeight: 600)
    #else
    .presentationDetents([.large])
    #endif
  }

  @ViewBuilder
  private var content: some View {
    let colors = results
    if colors.isEmpty {
      VStack(spacing: 16) {
        Image(systemName: mode == .favorites ? "heart" : "magnifyingglass")
          .font(.largeTitle)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
        if mode == .favorites {
          Text("No favorites yet").font(.headline)
          Text("Tap the heart on a color to keep it here.")
            .foregroundStyle(.secondary)
          Button("Browse colors") { dismiss() }
            .buttonStyle(.bordered)
        } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("Find your color").font(.headline)
          Text("Search all 365 colors by name, reading, story or HEX.")
            .foregroundStyle(.secondary)
        } else {
          Text("No matching colors").font(.headline)
          Text("Try another name or HEX value.")
            .foregroundStyle(.secondary)
        }
      }
      .multilineTextAlignment(.center)
      .padding(28)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      List(colors) { color in
        HStack(spacing: 12) {
          Button {
            onSelect(color)
          } label: {
            HStack(spacing: 14) {
              RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: color.hex))
                .frame(width: 48, height: 56)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.primary.opacity(0.15)))
                .accessibilityHidden(true)
              VStack(alignment: .leading, spacing: 4) {
                Text(color.kanji).font(.headline)
                Text(color.ruby).font(.subheadline).foregroundStyle(.secondary)
                Text("\(color.month).\(color.date) · \(color.hex)")
                  .font(.caption.monospacedDigit())
                  .foregroundStyle(.secondary)
              }
              Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityElement(children: .combine)
          .accessibilityIdentifier("library-color-\(color.id)")
          if mode == .favorites {
            FavoriteButton(color: color)
          }
        }
      }
      .listStyle(.plain)
      .accessibilityIdentifier("color-library-results")
    }
  }
}
#endif
