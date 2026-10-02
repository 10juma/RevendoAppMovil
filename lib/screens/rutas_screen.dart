import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/sesion.dart';
import '../models/usuario.dart';
import '../models/venta.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/filter_bar.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';

final _moneda = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 0,
);
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

Color _colorEstado(String estado) => switch (estado) {
  'Entregado' => AppColors.successText,
  'EnRuta' => const Color(0xFF2563EB),
  _ => AppColors.textMuted,
};

const _estadoOptions = [
  DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
  DropdownMenuItem(value: 'EnRuta', child: Text('En ruta')),
  DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
];

/// Mismo contenido y mismos filtros (Repartidor, Estado) que /Admin/Rutas en
/// el panel web. Asignar repartidor y cambiar estado ya son reales
/// (POST /api/ventas/{id}/asignar-repartidor y /estado).
class RutasScreen extends StatefulWidget {
  final Sesion sesion;
  const RutasScreen({super.key, required this.sesion});

  @override
  State<RutasScreen> createState() => _RutasScreenState();
}

class _RutasScreenState extends State<RutasScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Venta>>();

  String _buscar = '';
  String? _repartidor;
  String? _estado;
  List<String> _repartidoresDisponibles = [];
  List<Usuario> _repartidores = [];

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  bool get _hayFiltros => _repartidor != null || _estado != null;

  @override
  void initState() {
    super.initState();
    _cargarRepartidores();
  }

  Future<void> _cargarRepartidores() async {
    try {
      final data = await _api.listarEquipo();
      if (!mounted) return;
      setState(() {
        _repartidores = data
            .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
            .where((u) => u.rol == 'Repartidor' && u.activo)
            .toList();
      });
    } catch (_) {
      // Si falla, el modal de asignar simplemente sale sin opciones — no es
      // crítico para ver la lista de rutas.
    }
  }

  bool _filtro(Venta v) {
    if (_repartidor != null && v.repartidorNombre != _repartidor) {
      return false;
    }
    if (_estado != null && v.estadoEntrega != _estado) return false;
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return (v.clienteNombre?.toLowerCase().contains(b) ?? false) ||
        (v.repartidorNombre?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    String? repartidor = _repartidor;
    String? estado = _estado;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar rutas',
      onLimpiar: () => setState(() {
        _repartidor = null;
        _estado = null;
      }),
      onAplicar: () => setState(() {
        _repartidor = repartidor;
        _estado = estado;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Repartidor',
                valor: repartidor,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._repartidoresDisponibles.map(
                    (r) => DropdownMenuItem(value: r, child: Text(r)),
                  ),
                ],
                onChanged: (v) => setSheet(() => repartidor = v),
              ),
              FiltroDropdown<String?>(
                etiqueta: 'Estado',
                valor: estado,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._estadoOptions,
                ],
                onChanged: (v) => setSheet(() => estado = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirAcciones(Venta v) async {
    final repartidorActualId = _repartidores
        .firstWhere(
          (r) => r.nombre == v.repartidorNombre,
          orElse: () => Usuario(id: '', nombre: '', email: '', rol: '', activo: true, emailConfirmado: true),
        )
        .id;

    final repartidorIdInicial = repartidorActualId.isEmpty ? null : repartidorActualId;
    String? repartidorId = repartidorIdInicial;
    String estado = v.estadoEntrega;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.clienteNombre ?? 'Público general',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(error!, style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                  FormDropdown<String?>(
                    etiqueta: 'Repartidor',
                    valor: repartidorId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                      ..._repartidores.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre))),
                    ],
                    onChanged: (val) => setSheet(() => repartidorId = val),
                  ),
                  FormDropdown<String>(
                    etiqueta: 'Estado de entrega',
                    valor: estado,
                    items: _estadoOptions,
                    onChanged: (val) => setSheet(() => estado = val!),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (repartidorId != repartidorIdInicial) {
                            await _api.asignarRepartidor(v.id, repartidorId);
                          }
                          if (estado != v.estadoEntrega) {
                            await _api.cambiarEstadoEntrega(v.id, estado);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _listKey.currentState?.reload();
                        } on ApiException catch (e) {
                          setSheet(() => error = e.mensaje);
                        } catch (_) {
                          setSheet(() => error = 'No se pudo guardar — revisa tu internet.');
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Venta>(
      key: _listKey,
      titulo: 'Rutas de reparto',
      icono: IconosMenu.rutas,
      sesion: widget.sesion,
      vacioTexto: 'No hay ventas con reparto registradas.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por cliente o repartidor',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      onCargado: (items) {
        final nombres = items
            .map((v) => v.repartidorNombre)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
        setState(() => _repartidoresDisponibles = nombres);
      },
      fetch: (api) async {
        final data = await api.listarVentas();
        return data
            .map((e) => Venta.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, v) => InkWell(
        onTap: () => _abrirAcciones(v),
        child: InfoCard(
          titulo: v.clienteNombre ?? 'Público general',
          subtitulo: v.repartidorNombre ?? 'Sin repartidor asignado',
          trailing: v.estadoEntrega,
          trailingColor: _colorEstado(v.estadoEntrega),
          filas: [
            MapEntry('Fecha', _fecha(v.fecha)),
            MapEntry('Total', _moneda.format(v.total)),
            MapEntry('Almacén', v.almacenNombre),
          ],
        ),
      ),
    );
  }
}
