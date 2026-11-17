# AronaOS — experimental iOS / CarPlay video

Independent research project for a SEAT Arona 2021-ish (infotainment `575035816A / H40 / 0517`) and iPhone previously reported on iOS 26.4. Wired and wireless CarPlay confirmed; **video support unverified**.

### What changed after the Apple approval email

The developer has reported that Apple granted the **CarPlay Video App** entitlement to their account. The repo now contains only `com.apple.developer.carplay-video` — **not** CarPlay Audio. Since iOS 26.3, Apple says these categories cannot be combined in the same app. The entitlement remains **disabled by default** in `Signing.xcconfig` until the explicit App ID and a new provisioning profile are configured.

**Read [the Apple Video setup checklist](docs/APPLE_VIDEO_APPROVAL.md) before attempting to sign.**

## CarOs: escritorio personalizable en el iPhone

El objetivo real de CarOs es un lanzador multimedia configurable. En la rama experimental se ha añadido **una pantalla de inicio nativa de iPhone** con iconos de YouTube, TikTok, Movistar Plus+, ChatGPT y Navegador.

- Mantén pulsado un icono para **editar**, **mover antes/después**, **abrir dentro/fuera de CarOs** o **eliminar**.
- Pulsa **+ / Añadir** para guardar un acceso propio con nombre y URL HTTP(S).
- El orden y los accesos se guardan localmente con UserDefaults; no requieren servidor, suscripción ni cuenta.
- YouTube/Navegador se abren dentro del navegador de CarOs. TikTok, ChatGPT y Movistar Plus+ se abren fuera de la app de forma predeterminada, porque su experiencia de iPhone, identificación y contenido protegido pueden no funcionar en WKWebView. El acceso externo puede activar enlaces universales si el proveedor los admite.
- **No se instalan apps de terceros dentro de CarOs.** Son accesos directos, no una copia de Android ni un sistema operativo de coche.
- **La pantalla nativa de iPhone NO sustituye el Home de CarPlay ni aparece automáticamente en el SEAT.** Apple controla las pantallas CarPlay mediante el framework y plantillas. La ventana de coche heredada de Cafari Lite sigue siendo experimental. Es necesario diseñar una navegación CarPlay nativa de vídeo con la API oficial, usar AirPlay para reproducción compatible y certificar soporte por modelo.
- **Movistar Plus+ no garantiza reproducción en el coche**: Movistar requiere su app oficial en iPhone/iPad y aplica derechos y restricciones de reproducción/dispositivos.
- El workflow manual de firma en `main` está fijado a un commit anterior (`70eb234`) por seguridad. **No firmar ni subir automáticamente esta nueva funcionalidad** hasta pasar pruebas y actualizar deliberadamente ese pin.

Esto no modifica la pantalla o el firmware del coche, ni elude el bloqueo de vídeo en movimiento.

### Compatibility blockers

- Apple's **official CarPlay video apps were introduced in iOS 27**. Update the test iPhone to iOS 27+ before official tests, with an appropriate Xcode/iOS SDK.
- Video-only apps are **hidden on cars that lack the video feature**. We have not confirmed SEAT Arona 2021 support; account entitlement approval alone does not enable it.
- This branch adapts MIT-licensed [Cafari Lite](https://github.com/rPlayAI/cafari-lite) at upstream `fed8f84b6ab1e254a1fd8d59b144cb71d0f9798f`, Copyright (c) 2026 rPlay AI. See LICENSE. The existing UIKit/WKWebView car scene is **experimental**, not the final supported iOS 27 CarPlay video application. Apple's official path uses CarPlay framework and AirPlay-compatible video.
- The experimental CoreLocation motion gate is fail-closed on missing/invalid GPS, but GPS speed zero **cannot certify the car is parked**. Do not operate in-car video without trusted Apple/vehicle parked-state enforcement. Do not defeat the car's safety mechanisms.

### Code and tests

- `CafariLite/`: native Swift experimental baseline, builds for iPhone.
- `web/index.html`: AronaOS design concept running in a **normal browser**, not in CarPlay.
- `CarPlay.entitlements`: video-only permission; requires valid Apple-approved App ID and provisioning.
- `scripts/check_source.py`: static safety and entitlement assertions.
- `docs/TEST_PLAN.md`: remaining QA gates.

Unsigned smoke build on a compatible macOS/Xcode environment:
```sh
xcodebuild -project CafariLite.xcodeproj -scheme CafariLite -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

A successful compile is **not** a signed install, a vehicle test, or proof of video playback compatibility. No ECU/firmware changes, jailbreak, live payments or secrets.
