import 'package:flutter/material.dart';

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

const _tipoOptions = [
  DropdownMenuItem(value: 'Reventa', child: Text('Reventa directa')),
  DropdownMenuItem(value: 'Producido', child: Text('Producido (con receta)')),
  DropdownMenuItem(value: 'Insumo', child: Text('Insumo / materia prima')),
];

const _unidadOptions = [
  DropdownMenuItem(value: 'Pieza', child: Text('Pieza')),
  DropdownMenuItem(value: 'Kilogramo', child: Text('Kilogramo')),
  DropdownMenuItem(value: 'Gramo', child: Text('Gramo')),
  DropdownMenuItem(value: 'Litro', child: Text('Litro')),
  DropdownMenuItem(value: 'Mililitro', child: Text('Mililitro')),
];

class _FilaReceta {
  String? insumoId;
  final TextEditingController cantidad;
  _FilaReceta({this.insumoId, String? cantidad})
      : cantidad = TextEditingController(text: cantidad);
  void dispose() => cantidad.dispose();
}

/// Alta/edición de un producto — mismos campos que el modal de
/// /Admin/Productos en la web. La receta (solo si Tipo == Producido) se
/// guarda junto con el producto en un solo formulario (en la web son 2
/// pasos separados: "Guardar producto" y "Guardar receta").
class ProductoFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Producto? producto;
  const ProductoFormScreen({super.key, required this.sesion, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.producto?.nombre);
  late final _descripcion = TextEditingController(text: widget.producto?.descripcion);
  late final _marca = TextEditingController(text: widget.producto?.marca);
  late final _categoria = TextEditingController(text: widget.producto?.categoria);
  late final _sku = TextEditingController(text: widget.producto?.sku);
  late final _costo = TextEditingController(text: widget.producto?.costo?.toStringAsFixed(2));
  late final _precioVenta = TextEditingController(text: widget.producto?.precioVenta?.toStringAsFixed(2));
  late final _stockMinimo = TextEditingController(text: widget.producto?.stockMinimo?.toStringAsFixed(2));
  late String _tipo = widget.producto?.tipo ?? 'Reventa';
  late String _unidad = widget.producto?.unidadMedida ?? 'Pieza';
  late bool _manejaCaducidad = widget.producto?.manejaCaducidad ?? false;
  late bool _activo = widget.producto?.activo ?? true;

  bool _cargandoInsumos = true;
  List<Producto> _insumosDisponibles = [];
  late final List<_FilaReceta> _receta = widget.producto?.receta
          .map((r) => _FilaReceta(insumoId: r.insumoId, cantidad: r.cantidad.toString()))
          .toList() ??
      [];

  bool get _editando => widget.producto != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargarInsumos();
  }

  Future<void> _cargarInsumos() async {
    try {
      final data = await _api.listarProductos();
      if (!mounted) return;
      setState(() {
        _insumosDisponibles = data
            .map((e) => Producto.fromJson(e as Map<String, dynamic>))
            .where((p) => p.tipo == 'Insumo')
            .toList();
        _cargandoInsumos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoInsumos = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _marca.dispose();
    _categoria.dispose();
    _sku.dispose();
    _costo.dispose();
    _precioVenta.dispose();
    _stockMinimo.dispose();
    for (final f in _receta) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final receta = _receta
        .where((f) => f.insumoId != null && double.tryParse(f.cantidad.text.trim()) != null)
        .map((f) => {'insumoId': f.insumoId, 'cantidad': double.parse(f.cantidad.text.trim())})
        .toList();

    final body = {
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'tipo': _tipo,
      'unidadMedida': _unidad,
      'precioVenta': double.tryParse(_precioVenta.text.trim()),
      'costo': double.tryParse(_costo.text.trim()),
      'marca': _marca.text.trim(),
      'categoria': _categoria.text.trim(),
      'sku': _sku.text.trim(),
      'stockMinimo': double.tryParse(_stockMinimo.text.trim()),
      'manejaCaducidad': _manejaCaducidad,
      'activo': _activo,
      'receta': receta,
    };
    if (_editando) {
      await _api.actualizarProducto(widget.producto!.id, body);
    } else {
      await _api.crearProducto(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar producto' : 'Nuevo producto',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre',
          controller: _nombre,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Escribe el nombre del producto' : null,
        ),
        CampoTexto(etiqueta: 'Descripción', controller: _descripcion, maxLines: 3),
        FormDropdown<String>(
          etiqueta: 'Tipo',
          valor: _tipo,
          items: _tipoOptions,
          onChanged: (v) => setState(() => _tipo = v!),
        ),
        FormDropdown<String>(
          etiqueta: 'Unidad de medida',
          valor: _unidad,
          items: _unidadOptions,
          onChanged: (v) => setState(() => _unidad = v!),
        ),
        Row(
          children: [
            Expanded(
              child: CampoTexto(
                etiqueta: 'Costo',
                controller: _costo,
                teclado: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (v != null && v.trim().isNotEmpty && (n == null || n < 0)) {
                    return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CampoTexto(
                etiqueta: 'Precio de venta',
                controller: _precioVenta,
                teclado: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (v != null && v.trim().isNotEmpty && (n == null || n < 0)) {
                    return 'No puede ser negativo';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        CampoTexto(etiqueta: 'Marca', controller: _marca),
        CampoTexto(etiqueta: 'Categoría', controller: _categoria),
        CampoTexto(etiqueta: 'SKU', controller: _sku),
        CampoTexto(
          etiqueta: 'Stock mínimo',
          controller: _stockMinimo,
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
        FormSwitch(
          etiqueta: 'Maneja caducidad',
          valor: _manejaCaducidad,
          onChanged: (v) => setState(() => _manejaCaducidad = v),
        ),
        if (_editando)
          FormSwitch(
            etiqueta: 'Activo',
            valor: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
        if (_tipo == 'Producido') ...[
          FormSeccion(
            'Receta',
            accion: TextButton.icon(
              onPressed: _cargandoInsumos
                  ? null
                  : () => setState(() => _receta.add(_FilaReceta())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar insumo'),
            ),
          ),
          if (_cargandoInsumos) const Center(child: CircularProgressIndicator()),
          if (!_cargandoInsumos && _insumosDisponibles.isEmpty)
            const Text(
              'No tienes productos de tipo Insumo todavía — créalos primero para armar la receta.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          if (!_cargandoInsumos)
            ..._receta.asMap().entries.map((entry) {
              final i = entry.key;
              final fila = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: BuscadorCampo<Producto>(
                        etiqueta: 'Insumo',
                        valor: _buscarProducto(_insumosDisponibles, fila.insumoId),
                        opciones: _insumosDisponibles,
                        etiquetaDe: (p) => p.nombre,
                        hintBuscar: 'Buscar insumo',
                        onChanged: (p) => setState(() => fila.insumoId = p?.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: fila.cantidad,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cantidad', isDense: true),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        fila.dispose();
                        _receta.removeAt(i);
                      }),
                    ),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }
}
