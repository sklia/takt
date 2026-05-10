import Observation
import SwiftUI

@MainActor
@Observable
final class HUDModel {
    var artist: String = ""
    var title: String = ""
    var album: String?
    var albumArt: NSImage?

    func update(from event: PlaybackEvent) {
        artist = event.artist
        title = event.title
        album = event.album
        albumArt = nil
    }
}

struct HUDView: View {
    @State var model: HUDModel
    var style: HUDStyle = .standard

    var body: some View {
        switch style {
        case .standard: standardLayout
        case .compact: compactLayout
        }
    }

    private var standardLayout: some View {
        HStack(spacing: 14) {
            Group {
                if let art = model.albumArt {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(model.title)
                    .font(.title3.bold())
                    .lineLimit(1)
                Text(model.artist)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let album = model.album {
                    Text(album)
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(width: 340, alignment: .leading)
        .glassEffect(.regular, in: .capsule)
    }

    private var compactLayout: some View {
        HStack(spacing: 12) {
            Group {
                if let art = model.albumArt {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(model.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let album = model.album {
                    Text(album)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(width: 300, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
