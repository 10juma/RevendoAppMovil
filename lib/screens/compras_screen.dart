import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/compra.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'compra_detalle_screen.dart';
import 'compra_form_screen.dart';

final _moneda = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Mismo contenido y mismos filtros (Proveedor, Almacén, Desde/Hasta) que
/// /Admin/Compras en el panel web, de solo lectura.
class ComprasScreen extends StatefulWidget {
  final Sesion sesion;
  const ComprasScreen({super.key, required this.sesion});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Compra>>();

  String _buscar = '';
  String? _proveedor;
  String? _almacen;
  String? _usuario;
  DateTime? _desde;
  DateTime? _hasta;
  List<String> _proveedoresDisponibles = [];
  List<String> _almacenesDisponibles = [];
  List<String> _usuariosDisponibles = [];

  bool get _hayFiltros =>
      _proveedor != null ||
      _almacen != null ||
      _usuario != null ||
      _desde != null ||
      _hasta != null;

  bool _filtro(Compra c) {
    if (_proveedor != null && c.proveedorNombre != _proveedor) return false;
    if (_almacen != null && c.almacenNombre != _almacen) return false;
    if (_usuario != null && c.usuarioNombre != _usuario) return false;
    if (_desde != null && c.fecha.isBefore(_desde!)) return false;
    if (_hasta != null &&
        c.fecha.isAfter(_hasta!.add(const Duration(days: 1)))) {
      return false;
    }
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return c.proveedorNombre.toLowerCase().contains(b) ||
        c.almacenNombre.toLowerCase().contains(b) ||
        (c.nota?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    String? proveedor = _proveedor;
    String? almacen = _almacen;
    String? usuario = _usuario;
    DateTime? desde = _desde;
    DateTime? hasta = _hasta;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar compras',
      onLimpiar: () => setState(() {
        _proveedor = null;
        _almacen = null;
        _usuario = null;
        _desde = null;
        _hasta = null;
      }),
      onAplicar: () => setState(() {
        _proveedor = proveedor;
        _almacen = almacen;
        _usuario = usuario;
        _desde = desde;
        _hasta = hasta;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Proveedor',
                valor: proveedor,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._proveedoresDisponibles.map(
                    (p) => DropdownMenuItem(value: p, child: Text(p)),
                  ),
                ],
                onChanged: (v) => setSheet(() => proveedor = v),
              ),
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
                etiqueta: 'Usuario',
                valor: usuario,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos los usuarios')),
                  ..._usuariosDisponibles.map(
                    (u) => DropdownMenuItem(value: u, child: Text(u)),
                  ),
                ],
                onChanged: (v) => setSheet(() => usuario = v),
              ),
              FiltroFecha(
                etiqueta: 'Desde',
                valor: desde,
                onChanged: (v) => setSheet(() => desde = v),
              ),
              FiltroFecha(
                etiqueta: 'Hasta',
                valor: hasta,
                onChanged: (v) => setSheet(() => hasta = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CompraFormScreen(sesion: widget.sesion)),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  Future<void> _abrirDetalle(Compra c) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CompraDetalleScreen(sesion: widget.sesion, compra: c)),
    );
    if (cambio == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Compra>(
      key: _listKey,
      titulo: 'Compras',
      icono: IconosMenu.compras,
      sesion: widget.sesion,
      vacioTexto: 'No tienes compras registradas.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por proveedor, almacén o nota',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add_rounded),
      ),
      onCargado: (items) {
        setState(() {
          _proveedoresDisponibles =
              items.map((c) => c.proveedorNombre).toSet().toList()..sort();
          _almacenesDisponibles =
              items.map((c) => c.almacenNombre).toSet().toList()..sort();
          _usuariosDisponibles =
              items.map((c) => c.usuarioNombre).whereType<String>().toSet().toList()..sort();
        });
      },
      fetch: (api) async {
        final data = await api.listarCompras();
        return data
            .map((e) => Compra.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, c) => InkWell(
        onTap: () => _abrirDetalle(c),
        child: InfoCard(
          titulo: c.proveedorNombre,
          subtitulo: '${c.almacenNombre} · ${_fecha(c.fecha.toLocal())}',
          trailing: _moneda.format(c.total),
          filas: [
            MapEntry('Productos', '${c.items.length} línea(s)'),
            if (c.usuarioNombre != null) MapEntry('Registró', c.usuarioNombre!),
            if (c.nota != null) MapEntry('Nota', c.nota!),
          ],
          acciones: [
            TextButton.icon(
              onPressed: () => compartirTicketCompra(context, widget.sesion, c),
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Compartir'),
            ),
          ],
        ),
      ),
    );
  }
}
