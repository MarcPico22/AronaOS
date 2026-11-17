# CarOs — Plan de pruebas (17/11/2026)

La interfaz de iPhone y el flujo de CarPlay Video están implementados a nivel de código, pero **no se ha probado físicamente en el SEAT** ni se ha subido esta revisión a TestFlight.

## A. Escritorio iPhone

1. Abrir CarOs. Comprobar accesos predeterminados a YouTube, TikTok, Movistar Plus+, ChatGPT y Navegador.
2. Pulsar + y añadir un enlace propio HTTPS. Editar, mover antes/después, cambiar icono, seleccionar abrir dentro/fuera y eliminar.
3. Elegir los cuatro temas; cerrar y abrir la app y verificar persistencia.
4. Restablecer iconos de fábrica; confirmar que se conservan tras reiniciar.
5. Abrir enlaces externos: no implica que la web funcione en CarPlay.

## B. Vídeos en iPhone

1. Entrar en Vídeos: en la primera instalación debe existir «Prueba HLS · Apple» (muestra pública de Apple). También se pueden añadir MP4, MOV o M3U8 directos propios/autorizados.
2. Asegurar rechazo de webs, HTTP y enlaces sin extensión de vídeo.
3. Reproducir usando el reproductor nativo AVPlayer.
4. Pulsar selector AirPlay; verificar solo receptores anunciados por el sistema.
5. Editar y eliminar vídeo; comprobar persistencia.
6. No eludir DRM, login ni restricciones de Movistar Plus+ o terceros.

## C. CarPlay Simulator compatible con Xcode 27

1. Instalar las Additional Tools de Xcode 27 que incluyen el simulador CarPlay y habilitar un receptor que soporte vídeo.
2. Verificar que CarOs aparece como app de vídeo cuando el simulador anuncia compatibilidad.
3. Abrir CarOs; deben mostrarse las plantillas del sistema: una cuadrícula con Mis vídeos y Compatibilidad.
4. Verificar que la pantalla de compatibilidad responde al dato real supportsVideoPlayback y que cada vídeo tiene ficha y botón con configuración de presentación de vídeo.
5. Seleccionar un vídeo MP4/HLS y verificar imagen/sonido mediante AirPlay. Este extremo NO ha sido certificado E2E.
6. Simular indisponibilidad del vídeo; no saltarse los controles del sistema.

## D. SEAT Arona 2021 — vehículo estacionado

1. Aparcar con el coche inmovilizado y conectar CarPlay por cable o inalámbrico.
2. Comprobar si aparece el icono de CarOs en el launcher de CarPlay. Si no aparece, no afirmar que falla la firma: podría ser que la unidad original no soporte vídeo.
3. Solo si aparece, abrir Compatibilidad y después Mis vídeos.
4. Seleccionar contenido propio/autorizado, comprobar el selector AirPlay en el iPhone y anotar si se reproduce.
5. Registrar versiones de iOS y multimedia, resultado y error visible. No empezar a circular para probar ni modificar los mecanismos del coche.
6. Si el coche no soporta oficialmente vídeo, detener esa parte de la prueba. CarOs seguirá siendo útil como escritorio de iPhone.

## E. Publicación

- Xcode 27 CI compilando es necesario, no suficiente.
- No subir a TestFlight ni modificar el commit firmado hasta haber revisado y compilado esta revisión.
- Mantener PR #1 como Draft. No publicar en la App Store sin QA y App Review.
- Nunca subir archivos .p12, .mobileprovision ni contraseñas a GitHub.

Referencias:
https://developer.apple.com/videos/play/wwdc2026/212/
https://developer.apple.com/documentation/carplay/cptemplateapplicationscene
https://developer.apple.com/documentation/carplay/cpsessionconfiguration/supportsvideoplayback
