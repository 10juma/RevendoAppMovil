import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/cliente.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'cliente_form_screen.dart';

/// Mismo contenido y mismos filtros (Buscar, Activo) que /Admin/Clientes en
/// el panel web. Visible para Admin y Vendedor (mismos roles que ya autoriza
/// /api/clientes). Crear/editar ya son reales (POST/PUT /api/clientes).
class ClientesScreen extends StatefulWidget {
  final Sesion sesion;
  const ClientesScreen({super.key, required this.sesion});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Cliente>>();

  String _buscar = '';
  bool? _activo;

  bool _filtro(Cliente c) {
    if (_activo != null && c.activo != _activo) return false;
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return c.nombre.toLowerCase().contains(b) ||
        (c.telefono?.toLowerCase().contains(b) ?? false) ||
        (c.email?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    bool? activo = _activo;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar clientes',
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

  Future<void> _abrirFormulario([Cliente? cliente]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClienteFormScreen(sesion: widget.sesion, cliente: cliente),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Cliente>(
      key: _listKey,
      titulo: 'Clientes',
      icono: IconosMenu.clientes,
      sesion: widget.sesion,
      vacioTexto: 'No tienes clientes registrados.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por nombre, teléfono o correo',
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
        final data = await api.listarClientes();
        return data
            .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, c) => InkWell(
        onTap: () => _abrirFormulario(c),
        child: InfoCard(
          titulo: c.nombre,
          subtitulo: c.telefono ?? c.email,
          inactivo: !c.activo,
          filas: [
            if (c.email != null && c.telefono != null)
              MapEntry('Correo', c.email!),
            if (c.direccion != null) MapEntry('Dirección', c.direccion!),
          ],
        ),
      ),
    );
  }
}
