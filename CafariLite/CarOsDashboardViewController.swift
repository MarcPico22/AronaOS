// CarOs native iPhone dashboard.
// Customizable, locally stored web shortcuts. This is NOT a replacement for the
// CarPlay system launcher. Apple's CarPlay framework controls the in-car UI.
import UIKit

private struct CarOsShortcut: Codable {
  var title: String
  var address: String
  var symbol: String
  var opensOutside: Bool

  static let defaults: [CarOsShortcut] = [
    .init(title: "YouTube", address: "https://m.youtube.com", symbol: "play.rectangle.fill", opensOutside: false),
    .init(title: "TikTok", address: "https://www.tiktok.com/", symbol: "music.note", opensOutside: true),
    .init(title: "Movistar Plus+", address: "https://www.movistarplus.es/", symbol: "tv.fill", opensOutside: true),
    .init(title: "ChatGPT", address: "https://chatgpt.com/", symbol: "sparkles", opensOutside: true),
    .init(title: "Navegador", address: "https://www.google.com/", symbol: "globe", opensOutside: false)
  ]
}

private enum CarOsTheme: String, CaseIterable {
  case noche, oceano, bosque, grafito

  var title: String {
    switch self {
    case .noche: return "Noche"
    case .oceano: return "Océano"
    case .bosque: return "Bosque"
    case .grafito: return "Grafito"
    }
  }

  var background: UIColor {
    switch self {
    case .noche: return UIColor(red: 0.045, green: 0.075, blue: 0.13, alpha: 1)
    case .oceano: return UIColor(red: 0.035, green: 0.15, blue: 0.24, alpha: 1)
    case .bosque: return UIColor(red: 0.04, green: 0.16, blue: 0.15, alpha: 1)
    case .grafito: return UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1)
    }
  }
}

final class CarOsDashboardViewController: UIViewController,
    UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  private let storageKey = "caros.shortcuts.v1"
  private let themeKey = "caros.theme.v1"
  private var theme: CarOsTheme {
    CarOsTheme(rawValue: UserDefaults.standard.string(forKey: themeKey) ?? "") ?? .noche
  }
  private var shortcuts = CarOsShortcut.defaults
  private var collectionView: UICollectionView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = theme.background
    navigationItem.title = "CarOs"
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationController?.navigationBar.tintColor = .white
    navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
    navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add, target: self, action: #selector(addShortcut))
    navigationItem.leftBarButtonItems = [
      UIBarButtonItem(title: "Vídeos", style: .plain, target: self,
                      action: #selector(openVideoLibrary)),
      UIBarButtonItem(title: "Personalizar", menu: makePersonalizeMenu())
    ]

    if let data = UserDefaults.standard.data(forKey: storageKey),
       let decoded = try? JSONDecoder().decode([CarOsShortcut].self, from: data) {
      shortcuts = decoded
    }

    let caption = UILabel()
    caption.text = "Mi escritorio · Mantén pulsado un icono para editarlo o moverlo.\nLos accesos abren webs o apps en el iPhone; no sustituyen CarPlay."
    caption.textColor = UIColor(red: 0.65, green: 0.73, blue: 0.85, alpha: 1)
    caption.font = .preferredFont(forTextStyle: .subheadline)
    caption.numberOfLines = 0
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 12
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 24, right: 16)

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.register(CarOsShortcutCell.self, forCellWithReuseIdentifier: "shortcut")
    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      caption.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      caption.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      collectionView.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 18),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])
  }

  @objc private func openVideoLibrary() {
    navigationController?.pushViewController(CarOsVideoLibraryViewController(), animated: true)
  }

  private func makePersonalizeMenu() -> UIMenu {
    let palettes = CarOsTheme.allCases.map { palette in
      UIAction(title: palette.title,
               image: UIImage(systemName: palette == theme ? "checkmark.circle.fill" : "circle")) { [weak self] _ in
        guard let self = self else { return }
        UserDefaults.standard.set(palette.rawValue, forKey: self.themeKey)
        self.view.backgroundColor = palette.background
        self.navigationItem.leftBarButtonItems?[1].menu = self.makePersonalizeMenu()
      }
    }
    let restore = UIAction(title: "Restablecer accesos predeterminados",
                           image: UIImage(systemName: "arrow.counterclockwise"),
                           attributes: .destructive) { [weak self] _ in
      self?.confirmReset()
    }
    return UIMenu(children: [UIMenu(title: "Color del escritorio", children: palettes), restore])
  }

  private func confirmReset() {
    let alert = UIAlertController(title: "Restablecer escritorio",
                                  message: "Se eliminarán los accesos personalizados y el orden guardado.",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
    alert.addAction(UIAlertAction(title: "Restablecer", style: .destructive) { [weak self] _ in
      self?.shortcuts = CarOsShortcut.defaults
      self?.saveAndRefresh()
    })
    present(alert, animated: true)
  }

  private func saveAndRefresh() {
    if let data = try? JSONEncoder().encode(shortcuts) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
    collectionView.reloadData()
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    shortcuts.count + 1 // Final tile: add a custom shortcut.
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shortcut", for: indexPath) as! CarOsShortcutCell
    if indexPath.item == shortcuts.count {
      cell.configure(title: "Añadir", symbol: "plus.circle.fill", color: UIColor(red: 0.25, green: 0.34, blue: 0.48, alpha: 1))
    } else {
      let item = shortcuts[indexPath.item]
      let color: UIColor
      switch item.symbol {
      case "play.rectangle.fill": color = UIColor(red: 0.64, green: 0.12, blue: 0.19, alpha: 1)
      case "tv.fill": color = UIColor(red: 0.08, green: 0.34, blue: 0.58, alpha: 1)
      case "sparkles": color = UIColor(red: 0.06, green: 0.39, blue: 0.34, alpha: 1)
      default: color = UIColor(red: 0.15, green: 0.23, blue: 0.39, alpha: 1)
      }
      cell.configure(title: item.title, symbol: item.symbol, color: color)
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = collectionView.bounds.width - 32
    let columns: CGFloat = width >= 600 ? 4 : (width >= 400 ? 3 : 2)
    let side = floor((width - (columns - 1) * 12) / columns)
    return CGSize(width: side, height: max(118, side * 0.75))
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard indexPath.item < shortcuts.count else { addShortcut(); return }
    let shortcut = shortcuts[indexPath.item]
    guard let url = URL(string: shortcut.address),
          let scheme = url.scheme?.lowercased(),
          ["http", "https"].contains(scheme),
          url.host != nil else { return }
    if shortcut.opensOutside {
      // Universal links may open their native iPhone app. No promise of CarPlay support.
      UIApplication.shared.open(url)
    } else {
      let browser = BrowserViewController(showsStatus: true, initialURL: url)
      browser.title = shortcut.title
      navigationController?.pushViewController(browser, animated: true)
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      contextMenuConfigurationForItemAt indexPath: IndexPath,
                      point: CGPoint) -> UIContextMenuConfiguration? {
    guard indexPath.item < shortcuts.count else { return nil }
    let index = indexPath.item
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
      guard let self = self, index < self.shortcuts.count else { return nil }
      var actions: [UIMenuElement] = []
      actions.append(UIAction(title: "Editar", image: UIImage(systemName: "pencil")) { [weak self] _ in
        self?.presentEditor(index: index)
      })
      actions.append(UIAction(title: "Cambiar icono", image: UIImage(systemName: "square.grid.2x2")) { [weak self] _ in
        self?.presentIconPicker(index: index)
      })
      if index > 0 {
        actions.append(UIAction(title: "Mover antes", image: UIImage(systemName: "arrow.left")) { [weak self] _ in
          guard let self = self, index < self.shortcuts.count else { return }
          self.shortcuts.swapAt(index, index - 1)
          self.saveAndRefresh()
        })
      }
      if index < self.shortcuts.count - 1 {
        actions.append(UIAction(title: "Mover después", image: UIImage(systemName: "arrow.right")) { [weak self] _ in
          guard let self = self, index + 1 < self.shortcuts.count else { return }
          self.shortcuts.swapAt(index, index + 1)
          self.saveAndRefresh()
        })
      }
      let mode = self.shortcuts[index].opensOutside
      actions.append(UIAction(title: mode ? "Abrir dentro de CarOs" : "Abrir fuera de CarOs",
                              image: UIImage(systemName: "arrow.up.right.square")) { [weak self] _ in
        guard let self = self, index < self.shortcuts.count else { return }
        self.shortcuts[index].opensOutside.toggle()
        self.saveAndRefresh()
      })
      actions.append(UIAction(title: "Eliminar", image: UIImage(systemName: "trash"),
                              attributes: .destructive) { [weak self] _ in
        guard let self = self, index < self.shortcuts.count else { return }
        self.shortcuts.remove(at: index)
        self.saveAndRefresh()
      })
      return UIMenu(children: actions)
    }
  }

  private func presentIconPicker(index: Int) {
    guard index < shortcuts.count else { return }
    let alert = UIAlertController(title: "Icono de " + shortcuts[index].title,
                                  message: "Elige el aspecto del acceso en tu iPhone.",
                                  preferredStyle: .actionSheet)
    let symbols: [(String, String)] = [
      ("Vídeo", "play.rectangle.fill"),
      ("Música", "music.note"),
      ("Televisión", "tv.fill"),
      ("IA", "sparkles"),
      ("Internet", "globe"),
      ("Mensajes", "message.fill"),
      ("Fotos", "photo.fill"),
      ("Juego", "gamecontroller.fill"),
      ("Favorito", "star.fill"),
      ("Coche", "car.fill")
    ]
    for (label, symbol) in symbols {
      alert.addAction(UIAlertAction(title: label, style: .default) { [weak self] _ in
        guard let self = self, index < self.shortcuts.count else { return }
        self.shortcuts[index].symbol = symbol
        self.saveAndRefresh()
      })
    }
    alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY,
                                 width: 1, height: 1)
    }
    present(alert, animated: true)
  }

  @objc private func addShortcut() { presentEditor(index: nil) }

  private func presentEditor(index: Int?) {
    let existing = index.flatMap { $0 < shortcuts.count ? shortcuts[$0] : nil }
    let alert = UIAlertController(
      title: existing == nil ? "Añadir acceso" : "Editar acceso",
      message: "Puedes añadir enlaces web. Esto no instala apps ni permite ejecutarlas en CarPlay.",
      preferredStyle: .alert)
    alert.addTextField {
      $0.placeholder = "Nombre (por ejemplo, Mi IA)"
      $0.text = existing?.title
      $0.autocapitalizationType = .words
    }
    alert.addTextField {
      $0.placeholder = "https://ejemplo.com"
      $0.text = existing?.address
      $0.keyboardType = .URL
      $0.autocapitalizationType = .none
      $0.autocorrectionType = .no
    }
    alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
    alert.addAction(UIAlertAction(title: "Guardar", style: .default) { [weak self, weak alert] _ in
      guard let self = self, let fields = alert?.textFields, fields.count == 2 else { return }
      let title = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let address = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !title.isEmpty, title.count <= 40,
            let url = URL(string: address),
            let scheme = url.scheme?.lowercased(),
            ["https", "http"].contains(scheme), url.host != nil else {
        self.showInvalidShortcut()
        return
      }
      let new = CarOsShortcut(title: title, address: address,
                              symbol: existing?.symbol ?? "globe",
                              opensOutside: existing?.opensOutside ?? false)
      if let index = index, index < self.shortcuts.count {
        self.shortcuts[index] = new
      } else {
        self.shortcuts.append(new)
      }
      self.saveAndRefresh()
    })
    present(alert, animated: true)
  }

  private func showInvalidShortcut() {
    let alert = UIAlertController(title: "Acceso no válido",
                                  message: "Introduce un nombre de hasta 40 caracteres y una dirección https:// válida.",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
    present(alert, animated: true)
  }
}

private final class CarOsShortcutCell: UICollectionViewCell {
  private let symbolView = UIImageView()
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.cornerRadius = 20
    contentView.layer.masksToBounds = true
    contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
    contentView.layer.borderWidth = 1

    symbolView.tintColor = .white
    symbolView.contentMode = .scaleAspectFit
    symbolView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(symbolView)

    titleLabel.textColor = .white
    titleLabel.font = .preferredFont(forTextStyle: .subheadline)
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.minimumScaleFactor = 0.75
    titleLabel.numberOfLines = 2
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      symbolView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      symbolView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -16),
      symbolView.widthAnchor.constraint(equalToConstant: 42),
      symbolView.heightAnchor.constraint(equalToConstant: 42),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
    ])
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

  func configure(title: String, symbol: String, color: UIColor) {
    contentView.backgroundColor = color
    symbolView.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .medium))
    titleLabel.text = title
    accessibilityLabel = title
    isAccessibilityElement = true
    accessibilityTraits = .button
  }
}
