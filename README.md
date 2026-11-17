# CarOs — Escritorio iPhone + exploración oficial CarPlay Video (experimental)

Aplicación iOS personalizable para iPhone con una segunda experiencia opcional de vídeo en CarPlay. Proyecto privado de investigación del propietario de un SEAT Arona 2021 (unidad infotainment `575035816A`, hardware H40, software 0517). **No está demostrado que este modelo de coche admita CarPlay Video.**

## Escritorio iPhone — implementado

En iPhone, CarOs abre una cuadrícula de accesos predeterminados: YouTube, TikTok, Movistar Plus+, ChatGPT y navegador web.

- Añadir, editar y borrar accesos HTTP(S) propios.
- Personalizar el icono (SF Symbols) y el color general del escritorio (Noche, Océano, Bosque, Grafito).
- Mover accesos antes/después con una pulsación prolongada.
- Elegir abrir en navegador web integrado o usar enlaces universales en apps de iPhone cuando el proveedor los admita.
- Restablecer el escritorio inicial y guardar orden, iconos, color y accesos en `UserDefaults`.
- No necesita cuenta, Supabase, Vercel, pagos ni backend; no instala ni ejecuta otras apps *dentro* de CarOs.

## Vídeos directos y AirPlay — implementado a nivel de código, QA pendiente

En **Vídeos** del iPhone, la primera apertura incluye un ejemplo HLS público de Apple para pruebas (se puede eliminar). También puedes añadir, editar, reproducir o eliminar vídeos propios con URL directa HTTPS terminada en `.mp4`, `.mov` o `.m3u8`. La pantalla de reproducción usa `AVPlayerViewController`, una capa nativa `AVPlayerLayer`, sesión `.moviePlayback`, controles Now Playing, `AVPlayer.allowsExternalPlayback = true` y el selector nativo `AVRoutePickerView` para elegir salida compatible.

Esto **no** reproduce por arte de magia un enlace web de YouTube/TikTok/Movistar Plus+ ni elude DRM, suscripciones o protecciones de contenidos. No recopila claves ni contraseñas.

## CarPlay — ruta oficial de Apple; compatibilidad física pendiente

El antiguo `UIWindowScene` personalizado de Cafari Lite se ha reemplazado por la API oficial:

- `CPTemplateApplicationScene` con `CPTemplateApplicationSceneDelegate` y su rol correcto en `Info.plist`.
- `CPGridTemplate` para la entrada a **Mis vídeos** y a **Compatibilidad**.
- `CPListTemplate` para explorar vídeos directos y fichas de reproducción con `CPListTemplateDetailsHeader` y `CPPlaybackConfiguration(preferredPresentation: .video)`.
- `CPSessionConfiguration.supportsVideoPlayback` (iOS 27+) para comprobar si el coche anuncia la capacidad de vídeo; no se falsea.
- `AVPlayer` preparado para salida externa/AirPlay; **falta certificar** en un CarPlay compatible que el audio y vídeo se enrutan y se presentan de forma correcta. No se declara reproducción real exitosa.
- Solo `com.apple.developer.carplay-video`, sin permiso de CarPlay Audio.
- Apple/vehículo son responsables del estado que permite mostrar vídeo únicamente estacionado; **no hay simulador de marcha Parking ni bypass**. La velocidad GPS no se usa como prueba de estacionamiento en la nueva escena.

**Limitaciones explícitas**: Apple no deja sustituir la pantalla de inicio del vehículo ni ejecutar cualquier app de iPhone desde una app CarPlay. Los iconos de webs, IA, TikTok y Movistar Plus+ son accesos **en el iPhone**, no apps ejecutables en la pantalla del SEAT. Un vehículo sin CarPlay Video puede ocultar CarOs por completo. Si el receptor no admite la ruta AirPlay de vídeo, instalar y firmar la IPA no lo cambia.

## Estado de publicación

- PR de trabajo: [#1](https://github.com/MarcPico22/AronaOS/pull/1) (Draft).
- Requisito mínimo del proyecto iOS: iOS 27. CI: `.github/workflows/unsigned-build.yml` compila en Xcode 27 con pruebas estáticas.
- Firma: `main` incluye un workflow **manual** de archivo IPA App Store firmado. Solo usa GitHub Actions Secrets y está fijado a un commit auditado. **No sube automáticamente a TestFlight ni publica en App Store**.
- El usuario tiene autorizado el CarPlay Video App entitlement según el correo de Apple y ha generado el perfil de distribución para `com.marcpico.aronaos`. La comprobación local del P12/perfil dio todos los resultados esperados.
- Ningún secreto, P12, perfil de provisión ni contraseña debe entrar al repositorio público.
- Aún faltan pruebas en CarPlay Simulator con vídeo habilitado, QA de iPhone/TestFlight, compatibilidad del Arona, pruebas de ruta AirPlay y conformidad con App Review.

Consulta [plan de pruebas](docs/PRUEBAS_CAROS.md) y [guía de firma en Windows](docs/SIGNED_IPA_WINDOWS.md).

## Origen

Derivado del proyecto MIT [Cafari Lite](https://github.com/rPlayAI/cafari-lite) (rPlay AI). Se conserva `LICENSE` y el código original no utilizado se mantiene como referencia experimental, no como interfaz CarPlay oficial. No se altera firmware del coche, ECU ni CarPlay original.

## Referencias oficiales

- https://developer.apple.com/videos/play/wwdc2026/212/
- https://developer.apple.com/documentation/carplay/cptemplateapplicationscene
- https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback
- https://developer.apple.com/carplay/
