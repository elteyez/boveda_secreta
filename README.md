# Bóveda segura · Autenticación biométrica con Flutter

App de ejemplo del video **"Autenticación biométrica con Flutter"** — Programación Móvil · SS603, Grupo 04.
Autores: **Gaylet Paternina** y **Josue Tellez**.

Una "bóveda" que solo se abre con la huella (o el rostro) del dueño del teléfono, usando el paquete oficial
[`local_auth`](https://pub.dev/packages/local_auth) **3.0.2**. La app nunca ve la huella: el sistema operativo
la compara dentro de la zona segura del procesador y solo responde **sí o no**.

## Qué demuestra

| # | Caso | Qué pasa |
|---|------|----------|
| 1 | Huella correcta | `authenticate` devuelve `true` y se muestra el contenido secreto |
| 2 | Huella incorrecta | El diálogo de Android permite reintentar; tras varios fallos llega `temporaryLockout` / `biometricLockout` |
| 3 | El usuario cancela | Llega `userCanceled` → "Cancelaste la autenticación." (en Android equivale a negar el permiso) |
| 4 | Sin huellas registradas | `getAvailableBiometrics()` devuelve una lista vacía → ni siquiera se abre el diálogo |
| 5 | Web | `kIsWeb` → "La biometría no está disponible en la Web." (`local_auth` no soporta navegadores) |

## Configuración por plataforma

| Plataforma | Qué se configura | ¿Diálogo de permiso? |
|---|---|---|
| Android | `USE_BIOMETRIC` en [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) y [`MainActivity`](android/app/src/main/kotlin/com/ejemplo/boveda_segura/MainActivity.kt) hereda de `FlutterFragmentActivity` | No, se concede al instalar |
| iOS | `NSFaceIDUsageDescription` en [`Info.plist`](ios/Runner/Info.plist) | Sí con Face ID, no con Touch ID |
| Web | Nada: `local_auth` no la soporta (la alternativa es WebAuthn con HTTPS) | No aplica |

## El código importante

Todo está en [`lib/main.dart`](lib/main.dart):

- `_comprobarDispositivo()` — antes de pedir la huella revisa: Web (`kIsWeb`), sensor (`canCheckBiometrics`) y huellas registradas (`getAvailableBiometrics`).
- `_desbloquear()` — llama a `authenticate(localizedReason: ..., biometricOnly: true)`.
- `_mensajeDeError()` — traduce cada `LocalAuthExceptionCode` a un mensaje claro, con un caso por defecto.

## Cómo ejecutarla

Requisitos: Flutter 3.x y un teléfono Android con una huella registrada y bloqueo de pantalla (PIN o patrón).

```bash
flutter pub get
flutter run            # en el teléfono conectado por USB
flutter run -d chrome  # para ver el caso Web
```

> **Nota:** algunos teléfonos (por ejemplo vivo o Samsung) muestran en negro el diálogo de huella en las grabaciones
> de pantalla por seguridad. Para grabar la demostración filmamos el teléfono con otra cámara.
