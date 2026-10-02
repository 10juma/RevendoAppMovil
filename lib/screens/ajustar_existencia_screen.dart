import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/existencia.dart';
import '../models/producto.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/buscador_campo.dart';
import '../widgets/form_scaffold.dart';

Producto? _buscarProducto(List<Producto> lista, String? id) {
  if (id == null) return null;
  for (final p in lista) {
    if (p.id == id) return p;
  }
  return null;
}

/// Ajustar la existencia de un producto en un almacén — mismo modal
/// "Ajustar existencia" de /Admin/Existencias en la web: pone la cantidad en
/// un valor absoluto, el servidor calcula el delta y registra el movimiento.
class AjustarExistenciaScreen extends StatefulWidget {
  final Sesion sesion;
  final Existencia? existencia;
  const AjustarExistenciaScreen({super.key, required this.sesion, this.existencia});

  @override
  State<AjustarExistenciaScreen> createState() => _AjustarExistenciaScreenState();
}

class _AjustarExistenciaScreenState extends State<AjustarExistenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _productoId;
  String? _almacenId;
  late final _cantidad = TextEditingController(
    text: widget.existencia?.cantidad.toStringAsFixed(2),
  );
  final _nota = TextEditingController();

  bool _cargando = true;
  List<Producto> _productos = [];
  List<Almacen> _almacenes = [];

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _productoId = widget.existencia?.productoId;
    _almacenId = widget.existencia?.almacenId;
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final productos = await _api.listarProductos();
      final almacenes = await _api.listarAlmacenes();
      if (!mounted) return;
      setState(() {
        _productos = productos.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
        _almacenes = almacenes.map((e) => Almacen.fromJson(e as Map<String, dynamic>)).toList();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _nota.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    await _api.ajustarExistencia({
      'productoId': _productoId,
      'almacenId': _almacenId,
      'cantidadNueva': double.parse(_cantidad.text.trim()),
      'nota': _nota.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ajustar existencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return FormScaffold(
      titulo: 'Ajustar existencia',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        BuscadorCampo<Producto>(
          etiqueta: 'Producto',
          valor: _buscarProducto(_productos, _productoId),
          opciones: _productos,
          etiquetaDe: (p) => p.nombre,
          subtituloDe: (p) => p.sku,
          hintBuscar: 'Buscar producto',
          onChanged: (p) => setState(() => _productoId = p?.id),
          validator: (p) => p == null ? 'Selecciona un producto' : null,
        ),
        FormDropdown<String>(
          etiqueta: 'Almacén',
          valor: _almacenId,
          items: _almacenes
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
              .toList(),
          onChanged: (v) => setState(() => _almacenId = v),
          validator: (v) => v == null ? 'Selecciona un almacén' : null,
        ),
        CampoTexto(
          etiqueta: 'Cantidad actual',
          controller: _cantidad,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final n = double.tryParse(v?.trim() ?? '');
            if (n == null || n < 0) return 'La cantidad no puede ser negativa';
            return null;
          },
        ),
        CampoTexto(etiqueta: 'Nota (opcional)', controller: _nota, maxLines: 2),
      ],
    );
  }
}
