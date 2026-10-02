import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/almacen.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'almacen_form_screen.dart';

/// Mismo contenido y mismos filtros que /Admin/Almacenes en el panel web
/// (Buscar, Tipo, Activo). Crear/editar ya son reales (POST/PUT /api/almacenes).
class AlmacenesScreen extends StatefulWidget {
  final Sesion sesion;
  const AlmacenesScreen({super.key, required this.sesion});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Almacen>>();

  String _buscar = '';
  String? _tipo;
  bool? _activo;

  bool get _hayFiltros => _tipo != null || _activo != null;

  bool _filtro(Almacen a) {
    if (_tipo != null && a.tipo != _tipo) return false;
    if (_activo != null && a.activo != _activo) return false;
    if (_buscar.trim().isEmpty) return true;
    return a.nombre.toLowerCase().contains(_buscar.trim().toLowerCase());
  }

  void _abrirFiltros() {
    String? tipo = _tipo;
    bool? activo = _activo;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar almacenes',
      onLimpiar: () => setState(() {
        _tipo = null;
        _activo = null;
      }),
      onAplicar: () => setState(() {
        _tipo = tipo;
        _activo = activo;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Tipo',
                valor: tipo,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'Bodega', child: Text('Bodega')),
                  DropdownMenuItem(
                    value: 'Tienda',
                    child: Text('Tienda / punto de venta'),
                  ),
                  DropdownMenuItem(
                    value: 'Vehiculo',
                    child: Text('Vehículo / ruta'),
                  ),
                ],
                onChanged: (v) => setSheet(() => tipo = v),
              ),
              FiltroTriEstado(
                etiqueta: 'Activo',
                valor: activo,
                onChanged: (v) => setSheet(() => activo = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario([Almacen? almacen]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AlmacenFormScreen(sesion: widget.sesion, almacen: almacen),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Almacen>(
      key: _listKey,
      titulo: 'Almacenes',
      icono: IconosMenu.almacenes,
      sesion: widget.sesion,
      vacioTexto: 'No tienes almacenes registrados.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por nombre',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      fetch: (api) async {
        final data = await api.listarAlmacenes();
        return data
            .map((e) => Almacen.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, a) => InkWell(
        onTap: () => _abrirFormulario(a),
        child: InfoCard(
          titulo: a.esPrincipal ? '${a.nombre} ⭐' : a.nombre,
          subtitulo: a.tipo,
          inactivo: !a.activo,
          filas: [
            if (a.direccion != null) MapEntry('Dirección', a.direccion!),
            if (a.telefono != null) MapEntry('Teléfono', a.telefono!),
          ],
        ),
      ),
    );
  }
}
