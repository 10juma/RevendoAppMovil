import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/proveedor.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'proveedor_form_screen.dart';

/// Mismo contenido y mismos filtros (Buscar, Activo) que /Admin/Proveedores
/// en el panel web. Crear/editar ya son reales (POST/PUT /api/proveedores).
class ProveedoresScreen extends StatefulWidget {
  final Sesion sesion;
  const ProveedoresScreen({super.key, required this.sesion});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Proveedor>>();

  String _buscar = '';
  bool? _activo;

  bool _filtro(Proveedor p) {
    if (_activo != null && p.activo != _activo) return false;
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return p.nombre.toLowerCase().contains(b) ||
        (p.contacto?.toLowerCase().contains(b) ?? false) ||
        (p.email?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    bool? activo = _activo;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar proveedores',
      onLimpiar: () => setState(() => _activo = null),
      onAplicar: () => setState(() => _activo = activo),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => FiltroTriEstado(
            etiqueta: 'Activo',
            valor: activo,
            onChanged: (v) => setSheet(() => activo = v),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario([Proveedor? proveedor]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProveedorFormScreen(sesion: widget.sesion, proveedor: proveedor),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Proveedor>(
      key: _listKey,
      titulo: 'Proveedores',
      icono: IconosMenu.proveedores,
      sesion: widget.sesion,
      vacioTexto: 'No tienes proveedores registrados.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por nombre, contacto o correo',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _activo != null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      fetch: (api) async {
        final data = await api.listarProveedores();
        return data
            .map((e) => Proveedor.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, p) => InkWell(
        onTap: () => _abrirFormulario(p),
        child: InfoCard(
          titulo: p.nombre,
          subtitulo: p.contacto,
          inactivo: !p.activo,
          filas: [
            if (p.telefono != null) MapEntry('Teléfono', p.telefono!),
            if (p.email != null) MapEntry('Correo', p.email!),
          ],
        ),
      ),
    );
  }
}
