import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/negocio.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../theme.dart';
import 'negocio_form_screen.dart';

/// Mismo contenido que /Admin/Negocio en el panel web, de solo lectura —
/// editar el perfil del negocio se sigue haciendo desde la web por ahora.
/// También es donde vive "Cerrar sesión" en la app (después de los datos
/// del negocio, no en el Dashboard).
class NegocioScreen extends StatefulWidget {
  final Sesion sesion;
  final VoidCallback onLogout;
  const NegocioScreen({super.key, required this.sesion, required this.onLogout});

  @override
  State<NegocioScreen> createState() => _NegocioScreenState();
}

class _NegocioScreenState extends State<NegocioScreen> {
  Negocio? _negocio;
  bool _cargando = true;
  String? _error;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _api.obtenerNegocio();
      if (!mounted) return;
      setState(() {
        _negocio = Negocio.fromJson(data);
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje == 'sesion_expirada'
            ? 'Tu sesión expiró — vuelve a entrar.'
            : e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  Future<void> _editar() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NegocioFormScreen(sesion: widget.sesion, negocio: _negocio!),
      ),
    );
    if (guardado == true) _cargar();
  }

  Future<void> _cerrarSesion() async {
    await AuthStorage.borrar();
    if (!mounted) return;
    // Esta pantalla está empujada encima del Dashboard: onLogout cambia la pantalla
    // de abajo a Login, pero esta seguiría tapándola — hay que cerrar todo lo que
    // esté encima de la ruta raíz.
    final navigator = Navigator.of(context);
    widget.onLogout();
    navigator.popUntil((ruta) => ruta.isFirst);
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cerrarSesion();
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloConIcono(icono: IconosMenu.negocio, texto: 'Mi negocio'),
        actions: [
          if (_negocio != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: _editar,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              )
            : _buildContenido(_negocio!),
      ),
    );
  }

  Widget _buildContenido(Negocio n) {
    final filas = [
      (Icons.notes_rounded, n.descripcion),
      (Icons.place_outlined, n.direccion),
      (Icons.call_outlined, n.telefono),
      (Icons.email_outlined, n.emailContacto),
      (Icons.facebook_outlined, n.facebook),
      (Icons.camera_alt_outlined, n.instagram),
      (Icons.chat_outlined, n.whatsApp),
    ].where((f) => f.$2 != null && f.$2!.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.badgeActiveBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                n.nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No has agregado más información de tu negocio todavía.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < filas.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          filas[i].$1,
                          size: 19,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            filas[i].$2!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _confirmarLogout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: const Text(
            'Cerrar sesión',
            style: TextStyle(color: AppColors.error),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ],
    );
  }
}
