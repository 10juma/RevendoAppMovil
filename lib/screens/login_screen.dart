import 'package:flutter/material.dart';

import '../models/sesion.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  final void Function(Sesion) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await const ApiClient().login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      final sesion = Sesion.fromJson(data);

      // Cualquier rol puede entrar — _Arranque decide qué pantalla mostrar
      // según sesion.rol (Repartidor → entregas, Admin/Vendedor → dashboard).
      await AuthStorage.guardar(data);
      if (!mounted) return;
      widget.onLogin(sesion);
    } on ApiException catch (e) {
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      setState(() {
        _error = 'No pudimos conectar — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El degradado vive en UN solo contenedor que cubre toda la pantalla
      // (verde oscuro arriba → se desvanece a blanco antes de llegar al
      // formulario) — nada de bloques de color separados.
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2E1A),
              Color(0xFF146A37),
              Color(0xFF16A34A),
              AppColors.bg,
            ],
            stops: [0, .22, .46, .78],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _circulo(260, Colors.white.withValues(alpha: .08)),
            ),
            Positioned(
              top: 120,
              left: -60,
              child: _circulo(170, Colors.white.withValues(alpha: .06)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/logo_1024x1024.jpeg',
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Revendo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Administra tu negocio sin complicaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Inventario, compras, ventas y reparto — todo en un solo '
                      'lugar, hecho para quien vende desde casa.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // El formulario SIEMPRE va en su propia tarjeta blanca sólida —
                    // nunca directo sobre el degradado, para que el texto se lea
                    // bien sin importar en qué tono de verde/blanco caiga detrás.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Bienvenido de nuevo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Inicia sesión en tu cuenta',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 22),
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Correo',
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Escribe tu correo'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Escribe tu contraseña'
                                  : null,
                              onFieldSubmitted: (_) => _entrar(),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: _cargando ? null : _entrar,
                              child: _cargando
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, size: 19),
                                        SizedBox(width: 8),
                                        Text('Entrar'),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circulo(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
