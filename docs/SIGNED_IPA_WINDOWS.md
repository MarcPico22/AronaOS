# CarOs: firmar la IPA desde Windows usando GitHub Actions

## Antes de empezar

Certificado y perfil comprobados localmente (según resultado del usuario): Apple Distribution sí; huellas coincidentes sí; Bundle ID `com.marcpico.aronaos` sí; CarPlay Video sí; CarPlay Audio no. **No se ha subido ningún certificado ni contraseña a GitHub.**

La app actual es **experimental**. Este flujo prepara una IPA firmada y **NO** la sube a TestFlight. La compatibilidad del SEAT Arona con vídeo sigue sin comprobarse; no usar vídeo con el vehículo en marcha.

La ejecución manual está definida en el branch `main`, y compila el código de `feat/cafari-lite-parked-prototype`. El workflow utiliza el runner oficial `xcode-27`.

## Paso 1 — GitHub: crear tres Secrets

Abre https://github.com/MarcPico22/AronaOS/settings/secrets/actions y selecciona **New repository secret**.

Crear **exactamente tres** secretos (sin pegarlos en chats, incidencias ni código):

1. `CAROS_P12_BASE64`: contenido Base64 del archivo `1and1padel-distribution-protected.p12`.
2. `CAROS_P12_PASSWORD`: contraseña del mismo archivo P12, introducida directamente en GitHub (sin mostrarla en PowerShell ni en chats).
3. `CAROS_PROFILE_BASE64`: contenido Base64 del archivo `CarOs_App_Store_Distribution.mobileprovision`.

### Generar Base64 localmente con PowerShell en Windows

Copia y ejecuta la siguiente línea **solo para el certificado**. No imprime el contenido: lo pone en el portapapeles para pegarlo inmediatamente en el valor del secret correspondiente:

```powershell
$desktop = [Environment]::GetFolderPath("Desktop")
$p12 = Join-Path $desktop "Apple\1and1padel-distribution-protected.p12"
[Convert]::ToBase64String([IO.File]::ReadAllBytes($p12)) | Set-Clipboard
```

Guarda ese contenido en `CAROS_P12_BASE64` en la web de GitHub. Después, ejecuta lo siguiente para el **perfil** y guarda su resultado en `CAROS_PROFILE_BASE64`:

```powershell
$desktop = [Environment]::GetFolderPath("Desktop")
$profile = Join-Path $desktop "CarOs_App_Store_Distribution.mobileprovision"
[Convert]::ToBase64String([IO.File]::ReadAllBytes($profile)) | Set-Clipboard
```

Después de pegar cada secreto y confirmar su guardado, limpia el portapapeles:

```powershell
Set-Clipboard -Value ""
```

**Aviso:** las copias de los certificados pueden quedar en el historial del portapapeles o sincronización de Windows si lo tienes activado. Desactiva/limpia ese historial si procede. Estos tres datos son sensibles; no los incluyas en capturas de pantalla, mensajes ni logs.

`CAROS_P12_PASSWORD` se introduce directamente desde el campo de la página de GitHub.

## Paso 2 — Lanzar manualmente la compilación

1. Abre https://github.com/MarcPico22/AronaOS/actions/workflows/caros-manual-signed.yml
2. Pulsa **Run workflow**. La workflow vive en `main`; mantén `main` seleccionado como fuente del workflow.
3. El job compilará exclusivamente la rama `feat/cafari-lite-parked-prototype` con Xcode 27.
4. Revisará la firma y que la única categoría CarPlay sea Video.
5. Si todo funciona, generará un artifact llamado **CarOs-signed-not-uploaded**. Retención: **1 día**. No lo sube a App Store Connect.

No ejecutes este workflow antes de que existan los tres Secrets. No fusionar PR #1 automáticamente.

## Paso 3 — Interpretar resultados

- `Missing Actions secret`: el secret no existe o está vacío.
- `No valid Apple Distribution identity`: revisar archivo P12/clave y validez.
- `Wrong App ID` / `CarPlay Video missing`: el perfil no es el perfil nuevo aprobado de CarOs.
- `CodeSign` / `No profiles for`: certificado, provisioning profile o equipo Apple mal configurados.
- `Archive succeeded` pero `exportArchive` falla: revisar la configuración de ExportOptions y firma manual.
- `CarOs-signed-not-uploaded` generado: IPA firmada técnicamente, **no instalada** y **no enviada** a TestFlight.

Para subir posteriormente a TestFlight harán falta una revisión de funcionalidad CarPlay y un método de autenticación con App Store Connect (idealmente API Key en GitHub Secrets). No activar aún subidas automáticas.

## Nota sobre seguridad y compatibilidad

- Este repositorio GitHub es **público**; nunca guardes el P12, perfil o contraseña como archivos/versiones del repo. GitHub Secrets va cifrado, pero cuida el acceso de escritura y los workflows que puedan usarlo.
- La clave de My Padel Partner sirve para firmar múltiples apps si la identidad y perfil coinciden, pero su exposición afectaría **a ambos proyectos**.
- App con entitlement aprobado ≠ coche compatible. Las apps de vídeo pueden estar ocultas cuando el sistema CarPlay no soporta vídeo.
- La protección basada solo en velocidad GPS **no demuestra que el vehículo esté aparcado**. Para reproducción en coche se debe respetar un estado de estacionamiento fiable de Apple/vehículo.
