import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/existencia.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'ajustar_existencia_screen.dart';

final _entero = NumberFormat.decimalPattern('es_MX');

/// Mismo contenido y mismos filtros que /Admin/Existencias en el panel web
/// (Buscar, Almacén, Tipo de producto, Con/sin existencia, Solo bajo
/// mínimo), de solo lectura.
class ExistenciasScreen extends StatefulWidget {
  final Sesion sesion;
  const ExistenciasScreen({super.key, required this.sesion});

  @override
  State<ExistenciasScreen> createState() => _ExistenciasScreenState();
}

class _ExistenciasScreenState extends State<ExistenciasScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Existencia>>();

  String _buscar = '';
  String? _almacen;
  String? _tipo;
  bool? _conExistencia;
  bool _soloBajo = false;
  List<String> _almacenesDisponibles = [];

  bool get _hayFiltros =>
      _almacen != null ||
      _tipo != null ||
      _conExistencia != null ||
      _soloBajo;

  bool _filtro(Existencia e) {
    if (_almacen != null && e.almacenNombre != _almacen) return false;
    if (_tipo != null && e.productoTipo != _tipo) return false;
    if (_conExistencia != null && (e.cantidad > 0) != _conExistencia) {
      return false;
    }
    if (_soloBajo &&
        !(e.stockMinimo != null && e.cantidad <= e.stockMinimo!)) {
      return false;
    }
    if (_buscar.trim().isEmpty) return true;
    return e.productoNombre.toLowerCase().contains(_buscar.trim().toLowerCase());
  }

  void _abrirFiltros() {
    String? almacen = _almacen;
    String? tipo = _tipo;
    bool? conExistencia = _conExistencia;
    bool soloBajo = _soloBajo;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar existencias',
      onLimpiar: () => setState(() {
        _almacen = null;
        _tipo = null;
        _conExistencia = null;
        _soloBajo = false;
      }),
      onAplicar: () => setState(() {
        _almacen = almacen;
        _tipo = tipo;
        _conExistencia = conExistencia;
        _soloBajo = soloBajo;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
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
              FiltroDropdown<String?>(
                etiqueta: 'Tipo de producto',
                valor: tipo,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'Reventa', child: Text('Reventa directa')),
                  DropdownMenuItem(
                    value: 'Producido',
                    child: Text('Producido (con receta)'),
                  ),
                  DropdownMenuItem(
                    value: 'Insumo',
                    child: Text('Insumo / materia prima'),
                  ),
                ],
                onChanged: (v) => setSheet(() => tipo = v),
              ),
              FiltroTriEstado(
                etiqueta: 'Existencia',
                valor: conExistencia,
                etiquetaSi: 'Con existencia',
                etiquetaNo: 'Sin existencia',
                onChanged: (v) => setSheet(() => conExistencia = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo por debajo del mínimo'),
                value: soloBajo,
                onChanged: (v) => setSheet(() => soloBajo = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario([Existencia? existencia]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AjustarExistenciaScreen(sesion: widget.sesion, existencia: existencia),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Existencia>(
      key: _listKey,
      titulo: 'Existencias',
      icono: IconosMenu.existencias,
      sesion: widget.sesion,
      vacioTexto: 'Sin existencias registradas.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar producto',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        tooltip: 'Ajustar existencia',
        child: const Icon(Icons.add_rounded),
      ),
      onCargado: (items) {
        final nombres = items.map((e) => e.almacenNombre).toSet().toList()
          ..sort();
        setState(() => _almacenesDisponibles = nombres);
      },
      fetch: (api) async {
        final data = await api.listarExistencias();
        return data
            .map((e) => Existencia.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, e) => InkWell(
        onTap: () => _abrirFormulario(e),
        child: InfoCard(
          titulo: e.productoNombre,
          subtitulo: e.almacenNombre,
          trailing: _entero.format(e.cantidad),
          trailingColor:
              e.stockMinimo != null && e.cantidad <= e.stockMinimo!
              ? const Color(0xFFDC2626)
              : null,
        ),
      ),
    );
  }
}
