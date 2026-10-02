import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/movimiento.dart';
import '../models/sesion.dart';
import '../theme.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'producir_screen.dart';

final _entero = NumberFormat.decimalPattern('es_MX');
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Mismo contenido y mismos filtros (Buscar, Almacén) que el historial de
/// /Admin/Produccion en el panel web. Reusa /api/movimientos filtrando a
/// Tipo == "Produccion" (MovimientosController ya documenta que cubre este
/// caso, no hay tabla separada para Producción). Producir ya es real
/// (POST /api/produccion).
class ProduccionScreen extends StatefulWidget {
  final Sesion sesion;
  const ProduccionScreen({super.key, required this.sesion});

  @override
  State<ProduccionScreen> createState() => _ProduccionScreenState();
}

class _ProduccionScreenState extends State<ProduccionScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Movimiento>>();

  String _buscar = '';
  String? _almacen;
  List<String> _almacenesDisponibles = [];

  bool get _hayFiltros => _almacen != null;

  bool _filtro(Movimiento m) {
    if (_almacen != null && m.almacenNombre != _almacen) return false;
    if (_buscar.trim().isEmpty) return true;
    return m.productoNombre.toLowerCase().contains(_buscar.trim().toLowerCase());
  }

  void _abrirFiltros() {
    String? almacen = _almacen;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar producción',
      onLimpiar: () => setState(() => _almacen = null),
      onAplicar: () => setState(() => _almacen = almacen),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => FiltroDropdown<String?>(
            etiqueta: 'Almacén',
            valor: almacen,
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ..._almacenesDisponibles.map(
                (a) => DropdownMenuItem(value: a, child: Text(a)),
              ),
            ],
            onChanged: (v) => setSheet(() => almacen = v),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirProducir() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProducirScreen(sesion: widget.sesion)),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Movimiento>(
      key: _listKey,
      titulo: 'Producción',
      icono: IconosMenu.produccion,
      sesion: widget.sesion,
      vacioTexto: 'Sin producciones registradas.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar producto',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirProducir,
        icon: const Icon(Icons.precision_manufacturing_outlined),
        label: const Text('Producir'),
      ),
      onCargado: (items) {
        final nombres = items.map((m) => m.almacenNombre).toSet().toList()
          ..sort();
        setState(() => _almacenesDisponibles = nombres);
      },
      fetch: (api) async {
        final data = await api.listarMovimientos();
        return data
            .map((e) => Movimiento.fromJson(e as Map<String, dynamic>))
            .where((m) => m.tipo == 'Produccion')
            .toList();
      },
      itemBuilder: (context, m) => InfoCard(
        titulo: m.productoNombre,
        subtitulo: '${m.almacenNombre} · ${_fecha(m.fecha)}',
        trailing:
            '${m.cantidad >= 0 ? '+' : ''}${_entero.format(m.cantidad)}',
        trailingColor: m.cantidad >= 0 ? AppColors.successText : AppColors.error,
        filas: [if (m.nota != null) MapEntry('Nota', m.nota!)],
      ),
    );
  }
}
