// User-managed direct video library on the iPhone.
// It does not bypass DRM or reproduce third-party native apps in the car.
import UIKit
import AVKit

final class CarOsVideoLibraryViewController: UITableViewController {
  private var videos = CarOsVideoLibrary.items

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Mis vídeos"
    view.backgroundColor = .systemBackground
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "video")

    let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addVideo))
    let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 42, height: 42))
    picker.prioritizesVideoDevices = true
    let airPlay = UIBarButtonItem(customView: picker)
    navigationItem.rightBarButtonItems = [add, airPlay]

    NotificationCenter.default.addObserver(self, selector: #selector(reloadVideos),
                                           name: CarOsVideoLibrary.changed, object: nil)
    tableView.tableFooterView = UIView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadVideos()
  }

  @objc private func reloadVideos() {
    videos = CarOsVideoLibrary.items
    tableView.reloadData()
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    max(1, videos.count)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "video", for: indexPath)
    var configuration = cell.defaultContentConfiguration()
    if videos.isEmpty {
      configuration.text = "Aún no hay vídeos"
      configuration.secondaryText = "Añade enlaces HTTPS directos .mp4 o .m3u8 con el botón +"
      cell.selectionStyle = .none
      cell.accessoryType = .none
    } else {
      let item = videos[indexPath.row]
      configuration.text = item.title
      configuration.secondaryText = item.mediaURL?.host ?? ""
      cell.accessoryType = .disclosureIndicator
      cell.selectionStyle = .default
    }
    cell.contentConfiguration = configuration
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard indexPath.row < videos.count else { return }
    let item = videos[indexPath.row]
    guard CarOsVideoPlayback.shared.play(item),
          let player = CarOsVideoPlayback.shared.player else { return }

    let controller = AVPlayerViewController()
    controller.player = player
    controller.allowsPictureInPicturePlayback = true
    present(controller, animated: true)
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    indexPath.row < videos.count
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                          forRowAt indexPath: IndexPath) {
    guard editingStyle == .delete, indexPath.row < videos.count else { return }
    videos.remove(at: indexPath.row)
    CarOsVideoLibrary.items = videos
  }

  override func tableView(_ tableView: UITableView,
                          contextMenuConfigurationForRowAt indexPath: IndexPath,
                          point: CGPoint) -> UIContextMenuConfiguration? {
    guard indexPath.row < videos.count else { return nil }
    let id = videos[indexPath.row].id
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      guard let self = self else { return nil }
      return UIMenu(children: [
        UIAction(title: "Editar vídeo", image: UIImage(systemName: "pencil")) { [weak self] _ in
          self?.presentEditor(id: id)
        }
      ])
    }
  }

  @objc private func addVideo() { presentEditor(id: nil) }

  private func presentEditor(id: UUID?) {
    let original = id.flatMap { id in videos.first { $0.id == id } }
    let alert = UIAlertController(
      title: original == nil ? "Añadir vídeo" : "Editar vídeo",
      message: "Pega un enlace HTTPS directo a .mp4, .mov o .m3u8. No valen webs, vídeos de YouTube ni contenidos DRM de Movistar Plus+.",
      preferredStyle: .alert)
    alert.addTextField { field in
      field.placeholder = "Nombre del vídeo"
      field.text = original?.title
      field.autocapitalizationType = .sentences
    }
    alert.addTextField { field in
      field.placeholder = "https://.../video.m3u8"
      field.text = original?.address
      field.keyboardType = .URL
      field.autocapitalizationType = .none
      field.autocorrectionType = .no
    }
    alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
    alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self, weak alert] _ in
      guard let self = self, let fields = alert?.textFields, fields.count == 2 else { return }
      let title = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let address = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !title.isEmpty, title.count <= 80,
            CarOsVideoLibrary.validMediaURL(address) != nil else {
        let error = UIAlertController(title: "Enlace no válido",
                                      message: "Introduce un nombre y URL HTTPS directa terminada en .mp4, .mov o .m3u8.",
                                      preferredStyle: .alert)
        error.addAction(UIAlertAction(title: "Aceptar", style: .default))
        self.present(error, animated: true)
        return
      }
      let video = CarOsVideo(title: title, address: address, id: original?.id ?? UUID())
      if let existingID = id, let index = self.videos.firstIndex(where: { $0.id == existingID }) {
        self.videos[index] = video
      } else {
        self.videos.append(video)
      }
      CarOsVideoLibrary.items = self.videos
    })
    present(alert, animated: true)
  }
}
