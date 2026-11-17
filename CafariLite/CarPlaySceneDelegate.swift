// CarOs CarPlay scene using the OFFICIAL CarPlay templates API.
// Video-only category. The old WKWebView-in-a-UIWindowScene hack is not used.
// In-car video requires a compatible vehicle, iOS 27+, AirPlay, and parked
// state enforcement by Apple/vehicle. We never simulate or bypass Park.
import CarPlay
import UIKit

final class CarPlaySceneDelegate: UIResponder,
                                  CPTemplateApplicationSceneDelegate,
                                  CPSessionConfigurationDelegate {
  private var interfaceController: CPInterfaceController?
  private var sessionConfiguration: CPSessionConfiguration?

  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
    self.interfaceController = interfaceController
    self.sessionConfiguration = CPSessionConfiguration(delegate: self)
    Log.write("CarOs official template scene connected")
    NotificationCenter.default.post(name: .cafariLiteCarConnected, object: nil)

    showHome()
  }

  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController) {
    self.interfaceController = nil
    self.sessionConfiguration = nil
    CarOsVideoPlayback.shared.stop()
    Log.write("CarOs CarPlay template scene disconnected")
    NotificationCenter.default.post(name: .cafariLiteCarDisconnected, object: nil)
  }

  func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                            contentStyleChanged contentStyle: CPContentStyle) {
    // CarPlay owns all colors/layout; no custom driver-facing windows.
  }

  private var isVideoCapable: Bool {
    if #available(iOS 27.0, *) {
      return sessionConfiguration?.supportsVideoPlayback ?? false
    }
    return false
  }

  private func showHome() {
    guard let controller = interfaceController else { return }

    // A grid of video-only actions. CarPlay never runs TikTok/Movistar+ or
    // arbitrary third-party iPhone apps from these tiles.
    let library = CPGridButton(
      titleVariants: ["Mis vídeos"],
      image: UIImage(systemName: "play.rectangle.fill")!) { [weak self] _ in
        self?.showVideoList()
      }
    let info = CPGridButton(
      titleVariants: ["Compatibilidad"],
      image: UIImage(systemName: "car.side.fill")!) { [weak self] _ in
        self?.showCompatibility()
      }
    let home = CPGridTemplate(title: "CarOs", gridButtons: [library, info])
    controller.setRootTemplate(home, animated: false, completion: nil)
  }

  private func showVideoList() {
    guard let controller = interfaceController else { return }
    let videoItems: [CPListItem]
    if !isVideoCapable {
      videoItems = [
        CPListItem(text: "Vídeo no disponible",
                   detailText: "Este coche o esta sesión no admite la función de vídeo.")
      ]
    } else if CarOsVideoLibrary.items.isEmpty {
      videoItems = [
        CPListItem(text: "Tu biblioteca está vacía",
                   detailText: "Añade vídeos MP4 o HLS desde el iPhone, en CarOs.")
      ]
    } else {
      videoItems = Array(CarOsVideoLibrary.items.prefix(20)).map { video in
        let item = CPListItem(text: video.title, detailText: "Vídeo · AirPlay, solo en coches compatibles")
        item.handler = { [weak self] _, completion in
          self?.showVideoDetail(video)
          completion()
        }
        return item
      }
    }
    let section = CPListSection(items: videoItems)
    let list = CPListTemplate(title: "Mis vídeos", sections: [section])
    controller.pushTemplate(list, animated: true, completion: nil)
  }

  private func showVideoDetail(_ video: CarOsVideo) {
    guard isVideoCapable, let controller = interfaceController else { return }
    let play = CPButton(image: UIImage(systemName: "play.fill")!) { [weak self] _ in
      guard self?.isVideoCapable == true else { return }
      _ = CarOsVideoPlayback.shared.play(video)
    }
    let thumbnail = CPThumbnailImage(image: UIImage(systemName: "play.rectangle.fill")!)
    let header = CPListTemplateDetailsHeader(
      thumbnail: thumbnail, title: video.title,
      subtitle: "Vídeo HTTPS · AirPlay · coche estacionado",
      actionButtons: [play])
    if #available(iOS 26.4, *) {
      header.playbackConfiguration = CPPlaybackConfiguration(
        preferredPresentation: .video,
        playbackAction: .play,
        elapsedTime: .zero,
        duration: .zero)
    }

    let info = CPListItem(
      text: "Reproducción mediante CarPlay",
      detailText: "Apple y el vehículo controlan cuándo mostrar vídeo.")
    let detail = CPListTemplate(
      title: video.title, sections: [CPListSection(items: [info])])
    detail.listHeader = header
    controller.pushTemplate(detail, animated: true, completion: nil)
  }

  private func showCompatibility() {
    guard let controller = interfaceController else { return }
    let status = isVideoCapable
      ? "CarPlay declara que el coche admite vídeo."
      : "Vídeo no compatible o no disponible en esta conexión."
    let items = [
      CPListItem(text: "Estado de CarPlay", detailText: status),
      CPListItem(text: "Reproducción", detailText: "AirPlay requiere un receptor y vehículo compatibles."),
      CPListItem(text: "Seguridad", detailText: "El coche y CarPlay limitan el vídeo al estacionamiento."),
      CPListItem(text: "Accesos externos", detailText: "TikTok, IA y Movistar+ se gestionan en el iPhone.")
    ]
    let list = CPListTemplate(title: "Compatibilidad", sections: [CPListSection(items: items)])
    controller.pushTemplate(list, animated: true, completion: nil)
  }
}

// Official CarPlay template scene session role from Apple's Info.plist specification.
let cafariLiteCarPlayRole = UISceneSession.Role(rawValue: "CPTemplateApplicationSceneSessionRoleApplication")

extension Notification.Name {
  static let cafariLiteCarConnected = Notification.Name("CafariLiteCarConnected")
  static let cafariLiteCarDisconnected = Notification.Name("CafariLiteCarDisconnected")
  static let cafariLiteAccountChanged = Notification.Name("CafariLiteAccountChanged")
  static let cafariLiteSendToCar = Notification.Name("CafariLiteSendToCar")
}
