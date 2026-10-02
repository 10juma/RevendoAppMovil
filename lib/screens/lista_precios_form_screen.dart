import 'package:flutter/material.dart';

import '../models/lista_precios.dart';
import '../models/producto.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/buscador_campo.dart';
import '../widgets/form_scaffold.dart';

Producto? _buscarProducto(List<Producto> lista, String? id) {
  if (id == null) return null;
  for (final p in lista) {
    if (p.id == id) return p;
  }
  return null;
}

class _Fila {
  String? productoId;
  final TextEditingController nombreMostrado;
  final TextEditingController precioLista;
  final TextEditingController descuento;

  _Fila({this.productoId, String? nombreMostrado, String? precioLista, String? descuento})
      : nombreMostrado = TextEditingController(text: nombreMostrado),
        precioLista = TextEditingController(text: precioLista),
        descuento = TextEditingController(text: descuento);

  void dispose() {
    nombreMostrado.dispose();
    precioLista.dispose();
    descuento.dispose();
  }
}

/// Alta/edición de una lista de precios — mismos campos que el modal de
/// /Admin/ListasPrecios en la web (nombre, activa, y productos con precio
/// especial y/o descuento y/o alias).
class ListaPreciosFormScreen extends StatefulWidget {
  final Sesion sesion;
  final ListaPrecios? lista;
  const ListaPreciosFormScreen({super.key, required this.sesion, this.lista});

  @override
  State<ListaPreciosFormScreen> createState() => _ListaPreciosFormScreenState();
}

class _ListaPreciosFormScreenState extends State<ListaPreciosFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.lista?.nombre);
  late bool _activa = widget.lista?.activa ?? false;

  bool _cargandoProductos = true;
  List<Producto> _productos = [];
  late final List<_Fila> _filas = widget.lista == null
      ? [_Fila()]
      : widget.lista!.items
          .map((i) => _Fila(
                productoId: i.productoId,
                nombreMostrado: i.nombreMostrado,
                precioLista: i.precioLista?.toStringAsFixed(2),
                descuento: i.descuentoPorcentaje?.toStringAsFixed(0),
              ))
          .toList();

  bool get _editando => widget.lista != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final data = await _api.listarProductos();
      if (!mounted) return;
      setState(() {
        _productos = data
            .map((e) => Producto.fromJson(e as Map<String, dynamic>))
            .where((p) => p.tipo != 'Insumo')
            .toList();
        _cargandoProductos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoProductos = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final items = <Map<String, dynamic>>[];
    for (final f in _filas) {
      if (f.productoId == null) continue;
      final precio = double.tryParse(f.precioLista.text.trim());
      final descuento = double.tryParse(f.descuento.text.trim());
      final alias = f.nombreMostrado.text.trim();
      if (precio == null && descuento == null && alias.isEmpty) continue;
      items.add({
        'productoId': f.productoId,
        'nombreMostrado': alias,
        'precioLista': precio,
        'descuentoPorcentaje': descuento,
      });
    }
    if (items.isEmpty) {
      throw ApiException(
          'Agrega al menos un producto con precio especial, descuento o nombre para mostrar');
    }

    final body = {'nombre': _nombre.text.trim(), 'activa': _activa, 'items': items};
    if (_editando) {
      await _api.actualizarListaPrecios(widget.lista!.id, body);
    } else {
      await _api.crearListaPrecios(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar lista de precios' : 'Nueva lista de precios',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre',
          controller: _nombre,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Escribe un nombre para la lista' : null,
        ),
        FormSwitch(
          etiqueta: 'Lista activa',
          valor: _activa,
          onChanged: (v) => setState(() => _activa = v),
        ),
        FormSeccion(
          'Productos',
          accion: TextButton.icon(
            onPressed: _cargandoProductos
                ? null
                : () => setState(() => _filas.add(_Fila())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar'),
          ),
        ),
        if (_cargandoProductos) const Center(child: CircularProgressIndicator()),
        if (!_cargandoProductos)
          ..._filas.asMap().entries.map((entry) {
            final i = entry.key;
            final fila = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BuscadorCampo<Producto>(
                          etiqueta: 'Producto',
                          valor: _buscarProducto(_productos, fila.productoId),
                          opciones: _productos,
                          etiquetaDe: (p) => p.nombre,
                          subtituloDe: (p) => p.sku,
                          hintBuscar: 'Buscar producto',
                          onChanged: (p) => setState(() => fila.productoId = p?.id),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() {
                          fila.dispose();
                          _filas.removeAt(i);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fila.precioLista,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Precio especial', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: fila.descuento,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Descuento %', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: fila.nombreMostrado,
                    decoration: const InputDecoration(labelText: 'Nombre para mostrar (opcional)', isDense: true),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
