// Adapted from Cafari Lite, Copyright (c) 2026 rPlay AI, MIT licensed.
// AronaOS prototype: fail closed when location is missing, inaccurate or stale.
// This is NOT a certified vehicle-parked detector. The vehicle/OS safety policy
// must still prevent video playback in motion.
import CoreLocation
import Foundation

final class CarGate: NSObject, CLLocationManagerDelegate {
  static let shared = CarGate()
  static let stateChanged = Notification.Name("CafariLiteCarGateChanged")

  // "Moving" here means blocked: moving OR unable to verify stationary.
  private(set) var isMoving = true
  private let manager = CLLocationManager()
  private var running = false
  private var stationarySamples = 0
  private var lastReliableFix: Date?
  private var freshnessTimer: Timer?

  private override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = kCLDistanceFilterNone
    manager.pausesLocationUpdatesAutomatically = false
  }

  func start() {
    guard !running else { return }
    running = true
    setBlocked(true)
    stationarySamples = 0
    lastReliableFix = nil
    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
    manager.startUpdatingLocation()
    freshnessTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
      self?.checkFreshness()
    }
    Log.write("car gate started; blocked until recent stationary fixes")
  }

  func stop() {
    running = false
    freshnessTimer?.invalidate()
    freshnessTimer = nil
    manager.stopUpdatingLocation()
    lastReliableFix = nil
    stationarySamples = 0
    setBlocked(true)
  }

  private func setBlocked(_ blocked: Bool) {
    guard blocked != isMoving else { return }
    isMoving = blocked
    Log.write("car gate: \(blocked ? "blocked/unknown" : "stationary GPS fixes")")
    NotificationCenter.default.post(name: CarGate.stateChanged, object: nil)
  }

  private func checkFreshness() {
    guard running else { return }
    guard let lastReliableFix = lastReliableFix,
          Date().timeIntervalSince(lastReliableFix) <= 4 else {
      stationarySamples = 0
      setBlocked(true)
      return
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {
    guard running, let fix = locations.last else { return }
    guard abs(fix.timestamp.timeIntervalSinceNow) < 3,
          fix.horizontalAccuracy >= 0,
          fix.horizontalAccuracy <= 50,
          fix.speed >= 0 else {
      stationarySamples = 0
      setBlocked(true)
      return
    }
    lastReliableFix = Date()
    // > 0.5 m/s or an ambiguous speed: immediately block video.
    guard fix.speed <= 0.5 else {
      stationarySamples = 0
      setBlocked(true)
      return
    }
    stationarySamples += 1
    if stationarySamples >= 3 { setBlocked(false) }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    stationarySamples = 0
    lastReliableFix = nil
    setBlocked(true)
    Log.write("car gate: location unavailable; playback blocked")
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager.authorizationStatus != .authorizedAlways &&
       manager.authorizationStatus != .authorizedWhenInUse {
      stationarySamples = 0
      lastReliableFix = nil
      setBlocked(true)
    }
  }
}
