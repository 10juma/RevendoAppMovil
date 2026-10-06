import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/gasto.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'gasto_form_screen.dart';

final _moneda = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Mismo contenido y mismos filtros (Categoría, Desde/Hasta) que
/// /Admin/Gastos en el panel web. Crear/editar/eliminar ya son reales.
class GastosScreen extends StatefulWidget {
  final Sesion sesion;
  const GastosScreen({super.key, required this.sesion});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Gasto>>();

  String _buscar = '';
  String? _categoria;
  String? _usuario;
  DateTime? _desde;
  DateTime? _hasta;
  List<String> _categoriasDisponibles = [];
  List<String> _usuariosDisponibles = [];

  bool get _hayFiltros =>
      _categoria != null || _usuario != null || _desde != null || _hasta != null;

  bool _filtro(Gasto g) {
    if (_categoria != null && g.categoria != _categoria) return false;
    if (_usuario != null && g.usuarioNombre != _usuario) return false;
    if (_desde != null && g.fecha.isBefore(_desde!)) return false;
    if (_hasta != null &&
        g.fecha.isAfter(_hasta!.add(const Duration(days: 1)))) {
      return false;
    }
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return g.descripcion.toLowerCase().contains(b) ||
        g.categoria.toLowerCase().contains(b) ||
        (g.nota?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    String? categoria = _categoria;
    String? usuario = _usuario;
    DateTime? desde = _desde;
    DateTime? hasta = _hasta;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar gastos',
      onLimpiar: () => setState(() {
        _categoria = null;
        _usuario = null;
        _desde = null;
        _hasta = null;
      }),
      onAplicar: () => setState(() {
        _categoria = categoria;
        _usuario = usuario;
        _desde = desde;
        _hasta = hasta;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Categoría',
                valor: categoria,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ..._categoriasDisponibles.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setSheet(() => categoria = v),
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

  Future<void> _abrirFormulario([Gasto? gasto]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GastoFormScreen(sesion: widget.sesion, gasto: gasto),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Gasto>(
      key: _listKey,
      titulo: 'Gastos',
      icono: IconosMenu.gastos,
      sesion: widget.sesion,
      vacioTexto: 'No tienes gastos registrados.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por descripción, categoría o nota',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      onCargado: (items) {
        final categorias = items.map((g) => g.categoria).toSet().toList()
          ..sort();
        final usuarios = items.map((g) => g.usuarioNombre).whereType<String>().toSet().toList()
          ..sort();
        setState(() {
          _categoriasDisponibles = categorias;
          _usuariosDisponibles = usuarios;
        });
      },
      fetch: (api) async {
        final data = await api.listarGastos();
        return data
            .map((e) => Gasto.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, g) => InkWell(
        onTap: () => _abrirFormulario(g),
        child: InfoCard(
          titulo: g.descripcion,
          subtitulo: '${g.categoria} · ${_fecha(g.fecha)}',
          trailing: _moneda.format(g.monto),
          filas: [
            if (g.usuarioNombre != null) MapEntry('Registró', g.usuarioNombre!),
            if (g.nota != null) MapEntry('Nota', g.nota!),
          ],
        ),
      ),
    );
  }
}
