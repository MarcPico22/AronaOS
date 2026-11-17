// CarOs video library: direct HTTPS HLS/MP4 links, owned/authorized by the user.
// The native AVPlayer is AirPlay-capable, but CarPlay-in-car video still depends
// on a supported receiver and Apple's parked-only restrictions.
import Foundation
import AVFoundation

struct CarOsVideo: Codable, Equatable {
  var id: UUID
  var title: String
  var address: String

  init(title: String, address: String, id: UUID = UUID()) {
    self.id = id
    self.title = title
    self.address = address
  }

  var mediaURL: URL? { CarOsVideoLibrary.validMediaURL(address) }
}

enum CarOsVideoLibrary {
  static let changed = Notification.Name("CarOsVideoLibraryChanged")
  private static let storageKey = "caros.video-library.v1"

  static var items: [CarOsVideo] {
    get {
      // First launch only: a publicly documented Apple HLS sample for QA.
      // Once edited/deleted, the user's library is the single source of truth.
      guard let data = UserDefaults.standard.data(forKey: storageKey) else {
        return [CarOsVideo(title: "Prueba HLS · Apple",
                           address: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")]
      }
      guard let videos = try? JSONDecoder().decode([CarOsVideo].self, from: data) else {
        return []
      }
      return videos.filter { $0.mediaURL != nil }
    }
    set {
      guard let data = try? JSONEncoder().encode(newValue) else { return }
      UserDefaults.standard.set(data, forKey: storageKey)
      NotificationCenter.default.post(name: changed, object: nil)
    }
  }

  static func validMediaURL(_ address: String) -> URL? {
    guard address.count <= 2048,
          let components = URLComponents(string: address),
          components.scheme?.lowercased() == "https",
          let host = components.host, !host.isEmpty,
          components.user == nil, components.password == nil,
          let url = components.url else { return nil }

    // Links must point to a direct video file / playlist, not an arbitrary
    // website such as a Movistar+, TikTok or YouTube watch page.
    let path = url.path.lowercased()
    guard path.hasSuffix(".m3u8") || path.hasSuffix(".mp4") || path.hasSuffix(".mov") else { return nil }
    return url
  }
}

final class CarOsVideoPlayback {
  static let shared = CarOsVideoPlayback()
  private(set) var player: AVPlayer?

  private init() {}

  func play(_ video: CarOsVideo) -> Bool {
    guard let url = video.mediaURL else { return false }
    let next = AVPlayer(url: url)
    next.allowsExternalPlayback = true
    player?.pause()
    player = next
    next.play()
    return true
  }

  func stop() {
    player?.pause()
    player = nil
  }
}
