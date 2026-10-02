import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/sesion.dart';
import '../models/usuario.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'usuario_form_screen.dart';

/// Mismo contenido y mismos filtros (Buscar, Rol, Activo) que /Admin/Equipo
/// en el panel web. Crear/editar ya son reales (POST/PUT /api/equipo).
class EquipoScreen extends StatefulWidget {
  final Sesion sesion;
  const EquipoScreen({super.key, required this.sesion});

  @override
  State<EquipoScreen> createState() => _EquipoScreenState();
}

class _EquipoScreenState extends State<EquipoScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Usuario>>();

  String _buscar = '';
  String? _rol;
  bool? _activo;

  bool get _hayFiltros => _rol != null || _activo != null;

  bool _filtro(Usuario u) {
    if (_rol != null && u.rol != _rol) return false;
    if (_activo != null && u.activo != _activo) return false;
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return u.nombre.toLowerCase().contains(b) ||
        u.email.toLowerCase().contains(b);
  }

  void _abrirFiltros() {
    String? rol = _rol;
    bool? activo = _activo;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar equipo',
      onLimpiar: () => setState(() {
        _rol = null;
        _activo = null;
      }),
      onAplicar: () => setState(() {
        _rol = rol;
        _activo = activo;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Rol',
                valor: rol,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Vendedor', child: Text('Vendedor')),
                  DropdownMenuItem(
                    value: 'Repartidor',
                    child: Text('Repartidor'),
                  ),
                ],
                onChanged: (v) => setSheet(() => rol = v),
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

  Future<void> _abrirFormulario([Usuario? usuario]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioFormScreen(sesion: widget.sesion, usuario: usuario),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Usuario>(
      key: _listKey,
      titulo: 'Equipo',
      icono: IconosMenu.equipo,
      sesion: widget.sesion,
      vacioTexto: 'No hay usuarios registrados.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por nombre o correo',
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
        final data = await api.listarEquipo();
        return data
            .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, u) => InkWell(
        onTap: () => _abrirFormulario(u),
        child: InfoCard(
          titulo: u.nombre,
          subtitulo: u.email,
          trailing: u.rol,
          inactivo: !u.activo,
          filas: [
            MapEntry('Correo confirmado', u.emailConfirmado ? 'Sí' : 'No'),
          ],
        ),
      ),
    );
  }
}
