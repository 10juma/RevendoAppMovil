import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/lista_precios.dart';
import '../models/sesion.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'lista_precios_form_screen.dart';

String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Mismo contenido que /Admin/ListasPrecios en el panel web (sin filtros,
/// la web tampoco tiene ahí). Crear/editar ya son reales.
class ListasPreciosScreen extends StatefulWidget {
  final Sesion sesion;
  const ListasPreciosScreen({super.key, required this.sesion});

  @override
  State<ListasPreciosScreen> createState() => _ListasPreciosScreenState();
}

class _ListasPreciosScreenState extends State<ListasPreciosScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<ListaPrecios>>();

  Future<void> _abrirFormulario([ListaPrecios? lista]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ListaPreciosFormScreen(sesion: widget.sesion, lista: lista),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<ListaPrecios>(
      key: _listKey,
      titulo: 'Listas de precios',
      icono: IconosMenu.listasPrecios,
      sesion: widget.sesion,
      vacioTexto: 'No tienes listas de precios registradas.',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      fetch: (api) async {
        final data = await api.listarListasPrecios();
        return data
            .map((e) => ListaPrecios.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, l) => InkWell(
        onTap: () => _abrirFormulario(l),
        child: InfoCard(
          titulo: l.nombre,
          subtitulo: 'Creada el ${_fecha(l.creadoEn)}',
          trailing: l.activa ? 'Activa' : 'Inactiva',
          inactivo: !l.activa,
          filas: [MapEntry('Productos', '${l.items.length}')],
        ),
      ),
    );
  }
}
