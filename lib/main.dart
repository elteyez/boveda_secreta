import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() => runApp(const BovedaApp());

class BovedaApp extends StatelessWidget {
  const BovedaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bóveda segura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF7B23D),
          brightness: Brightness.dark,
          surface: const Color(0xFF0B1E29),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1E29),
      ),
      home: const BovedaPage(),
    );
  }
}

class BovedaPage extends StatefulWidget {
  const BovedaPage({super.key});

  @override
  State<BovedaPage> createState() => _BovedaPageState();
}

class _BovedaPageState extends State<BovedaPage> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _desbloqueada = false;
  String? _mensaje;

  /// Revisa si se puede pedir la huella en este dispositivo.
  /// Devuelve null si todo está bien, o un mensaje para el usuario.
  Future<String?> _comprobarDispositivo() async {
    // 1. local_auth no tiene implementación para Web.
    if (kIsWeb) return 'La biometría no está disponible en la Web.';

    // 2. ¿El dispositivo tiene sensor biométrico?
    if (!await _auth.canCheckBiometrics) {
      return 'Este dispositivo no tiene sensor biométrico.';
    }

    // 3. ¿Hay al menos una huella o un rostro registrado?
    final List<BiometricType> registradas =
        await _auth.getAvailableBiometrics();
    if (registradas.isEmpty) {
      return 'No hay huellas registradas. Agrega una en Ajustes.';
    }

    return null;
  }

  Future<void> _desbloquear() async {
    final String? problema = await _comprobarDispositivo();
    if (problema != null) {
      setState(() => _mensaje = problema);
      return;
    }

    try {
      final bool ok = await _auth.authenticate(
        localizedReason: 'Usa tu huella para abrir la bóveda',
        biometricOnly: true, // Solo biometría, sin PIN ni patrón.
      );
      setState(() {
        _desbloqueada = ok;
        _mensaje = ok ? 'Acceso concedido' : 'No se pudo verificar tu identidad.';
      });
    } on LocalAuthException catch (e) {
      setState(() => _mensaje = _mensajeDeError(e.code));
    }
  }

  String _mensajeDeError(LocalAuthExceptionCode codigo) {
    switch (codigo) {
      case LocalAuthExceptionCode.userCanceled:
        return 'Cancelaste la autenticación.';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return 'No hay huellas registradas. Agrega una en Ajustes.';
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'No se pudo autenticar. Intenta de nuevo.';
    }
  }

  void _bloquear() => setState(() {
        _desbloqueada = false;
        _mensaje = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _desbloqueada
                    ? _Contenido(key: const ValueKey('abierta'), onBloquear: _bloquear, mensaje: _mensaje)
                    : _Bloqueada(key: const ValueKey('cerrada'), onDesbloquear: _desbloquear, mensaje: _mensaje),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _ambar = Color(0xFFF7B23D);
const _tarjeta = Color(0xFF14303F);
const _borde = Color(0xFF2C5264);
const _gris = Color(0xFF84A0AC);

class _Bloqueada extends StatelessWidget {
  const _Bloqueada({super.key, required this.onDesbloquear, this.mensaje});
  final VoidCallback onDesbloquear;
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _tarjeta,
            border: Border.all(color: _ambar, width: 3),
          ),
          child: const Icon(Icons.lock_rounded, size: 56, color: _ambar),
        ),
        const SizedBox(height: 28),
        const Text('Bóveda segura',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Bóveda bloqueada', style: TextStyle(fontSize: 18, color: _gris)),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: FilledButton.icon(
            onPressed: onDesbloquear,
            style: FilledButton.styleFrom(
              backgroundColor: _ambar,
              foregroundColor: const Color(0xFF0E1E28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.fingerprint_rounded, size: 30),
            label: const Text('Desbloquear con huella',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 24),
        if (mensaje != null) _Aviso(texto: mensaje!),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final bool ok = texto == 'Acceso concedido';
    final Color color = ok ? const Color(0xFF60CE92) : const Color(0xFFF06868);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.info_rounded, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(texto,
                style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({super.key, required this.onBloquear, this.mensaje});
  final VoidCallback onBloquear;
  final String? mensaje;

  static const _secretos = [
    (Icons.wifi_rounded, 'Clave del WiFi', 'casa-2026-segura'),
    (Icons.credit_card_rounded, 'PIN de la tarjeta', '4 8 1 5'),
    (Icons.note_rounded, 'Nota privada', 'El examen es el viernes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: Color(0xFF60CE92), size: 34),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Contenido secreto',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (mensaje != null) _Aviso(texto: mensaje!),
        const SizedBox(height: 16),
        for (final (icono, titulo, valor) in _secretos)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _tarjeta,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borde),
            ),
            child: Row(
              children: [
                Icon(icono, color: _ambar, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontSize: 15, color: _gris)),
                      const SizedBox(height: 4),
                      Text(valor,
                          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onBloquear,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: _ambar, width: 2),
            foregroundColor: _ambar,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          icon: const Icon(Icons.lock_rounded),
          label: const Text('Bloquear de nuevo', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
