import 'package:flutter/material.dart';

import '../models/entrega.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../theme.dart';
import '../widgets/entrega_card.dart';

/// Mismo contenido que /Repartidor/Index.cshtml en el panel web: "Por
/// entregar" (todo lo que no esté Entregado) y "Entregadas recientemente"
/// (últimas 10) — el repartidor solo ve y mueve SUS entregas, la API ya se
/// encarga de eso del lado del servidor.
class EntregasScreen extends StatefulWidget {
  final Sesion sesion;
  final VoidCallback onLogout;

  const EntregasScreen({
    super.key,
    required this.sesion,
    required this.onLogout,
  });

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  List<Entrega> _entregas = [];
  bool _cargando = true;
  String? _error;
  String? _actualizandoId;

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
      final data = await _api.listarEntregas();
      if (!mounted) return;
      setState(() {
        _entregas = data
            .map((e) => Entrega.fromJson(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (e.mensaje == 'sesion_expirada') {
        await _cerrarSesion();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar tus entregas — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  Future<void> _avanzar(Entrega entrega) async {
    setState(() => _actualizandoId = entrega.id);
    try {
      await _api.avanzarEntrega(entrega.id);
      await _cargar();
    } on ApiException catch (e) {
      if (e.mensaje == 'sesion_expirada') {
        await _cerrarSesion();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos conectar — revisa tu internet.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actualizandoId = null);
    }
  }

  Future<void> _cerrarSesion() async {
    await AuthStorage.borrar();
    if (mounted) widget.onLogout();
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
    final porEntregar = _entregas
        .where((e) => e.estadoEntrega != 'Entregado')
        .toList();
    final entregadas = _entregas
        .where((e) => e.estadoEntrega == 'Entregado')
        .take(10)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis entregas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: _confirmarLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  _tituloSeccion('Por entregar'),
                  const SizedBox(height: 10),
                  if (porEntregar.isEmpty)
                    _tarjetaVacia('No tienes entregas pendientes por ahora.')
                  else
                    ...porEntregar.map(
                      (e) => EntregaCard(
                        entrega: e,
                        actualizando: _actualizandoId == e.id,
                        onAvanzar: () => _avanzar(e),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _tituloSeccion('Entregadas recientemente'),
                  const SizedBox(height: 10),
                  if (entregadas.isEmpty)
                    _tarjetaVacia('Aún no has entregado nada.')
                  else
                    ...entregadas.map(
                      (e) => EntregaCard(entrega: e, actualizando: false),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _tituloSeccion(String texto) => Text(
    texto,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: AppColors.text,
    ),
  );

  Widget _tarjetaVacia(String texto) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(texto, style: const TextStyle(color: AppColors.textMuted)),
  );
}
