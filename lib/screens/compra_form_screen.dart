import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/almacen.dart';
import '../models/compra.dart';
import '../models/producto.dart';
import '../models/proveedor.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/buscador_campo.dart';
import '../widgets/form_scaffold.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

class _Linea {
  Producto? producto;
  final TextEditingController cantidad = TextEditingController();
  final TextEditingController costo = TextEditingController();
  void dispose() {
    cantidad.dispose();
    costo.dispose();
  }
}

/// Alta o edición de una compra — mismos campos que el modal "Nueva compra" /
/// "Editar compra" de /Admin/Compras en la web. Editar concilia las
/// existencias ya movidas (lo hace el servidor, igual que la web).
class CompraFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Compra? compra;
  const CompraFormScreen({super.key, required this.sesion, this.compra});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _fechaSel = DateTime.now();
  Proveedor? _proveedorSel;
  String? _almacenId;
  final _nota = TextEditingController();
  final List<_Linea> _lineas = [_Linea()];

  bool _cargando = true;
  List<Proveedor> _proveedores = [];
  List<Almacen> _almacenes = [];
  List<Producto> _productos = [];

  bool get _editando => widget.compra != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final proveedores = await _api.listarProveedores();
      final almacenes = await _api.listarAlmacenes();
      final productos = await _api.listarProductos();
      if (!mounted) return;
      setState(() {
        _proveedores = proveedores
            .map((e) => Proveedor.fromJson(e as Map<String, dynamic>))
            .where((p) => p.activo || p.id == widget.compra?.proveedorId)
            .toList();
        _almacenes = almacenes
            .map((e) => Almacen.fromJson(e as Map<String, dynamic>))
            .where((a) => a.activo || a.id == widget.compra?.almacenId)
            .toList();
        _productos = productos.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
        _precargarCompra();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Al editar, rellena el formulario con lo que ya tiene la compra.
  void _precargarCompra() {
    final c = widget.compra;
    if (c == null) return;

    _fechaSel = c.fecha.toLocal();
    _almacenId = c.almacenId;
    _nota.text = c.nota ?? '';
    for (final p in _proveedores) {
      if (p.id == c.proveedorId) _proveedorSel = p;
    }

    for (final l in _lineas) {
      l.dispose();
    }
    _lineas
      ..clear()
      ..addAll(c.items.map((i) {
        final linea = _Linea();
        for (final p in _productos) {
          if (p.id == i.productoId) linea.producto = p;
        }
        linea.cantidad.text = i.cantidad.toString();
        linea.costo.text = i.costoUnitario.toStringAsFixed(2);
        return linea;
      }));
  }

  @override
  void dispose() {
    _nota.dispose();
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaSel,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegida != null) setState(() => _fechaSel = elegida);
  }

  void _onProductoElegido(_Linea linea, Producto? producto) {
    setState(() {
      linea.producto = producto;
      if (producto != null && producto.costo != null && linea.costo.text.isEmpty) {
        linea.costo.text = producto.costo!.toStringAsFixed(2);
      }
    });
  }

  Future<void> _guardar() async {
    final items = <Map<String, dynamic>>[];
    for (final l in _lineas) {
      final cantidad = double.tryParse(l.cantidad.text.trim());
      final costo = double.tryParse(l.costo.text.trim());
      if (l.producto == null || cantidad == null || cantidad <= 0 || costo == null || costo < 0) {
        continue;
      }
      items.add({'productoId': l.producto!.id, 'cantidad': cantidad, 'costoUnitario': costo});
    }
    if (items.isEmpty) {
      throw ApiException('Agrega al menos un producto con cantidad y costo');
    }

    final body = {
      'fechaCompra': _fechaSel.toIso8601String(),
      'proveedorId': _proveedorSel?.id,
      'almacenId': _almacenId,
      'nota': _nota.text.trim(),
      'items': items,
    };
    if (_editando) {
      await _api.actualizarCompra(widget.compra!.id, body);
    } else {
      await _api.crearCompra(body);
    }
  }

  double get _total {
    var total = 0.0;
    for (final l in _lineas) {
      final cantidad = double.tryParse(l.cantidad.text.trim()) ?? 0;
      final costo = double.tryParse(l.costo.text.trim()) ?? 0;
      total += cantidad * costo;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(_editando ? 'Editar compra' : 'Nueva compra')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return FormScaffold(
      titulo: _editando ? 'Editar compra' : 'Nueva compra',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Expanded(child: Text('Fecha: ${_fecha(_fechaSel)}')),
              OutlinedButton(onPressed: _elegirFecha, child: const Text('Cambiar')),
            ],
          ),
        ),
        BuscadorCampo<Proveedor>(
          etiqueta: 'Proveedor',
          valor: _proveedorSel,
          opciones: _proveedores,
          etiquetaDe: (p) => p.nombre,
          subtituloDe: (p) => p.contacto,
          hintBuscar: 'Buscar proveedor',
          onChanged: (p) => setState(() => _proveedorSel = p),
          validator: (p) => p == null ? 'Selecciona un proveedor' : null,
        ),
        FormDropdown<String>(
          etiqueta: 'Almacén de recepción',
          valor: _almacenId,
          items: _almacenes
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
              .toList(),
          onChanged: (v) => setState(() => _almacenId = v),
          validator: (v) => v == null ? 'Selecciona el almacén de recepción' : null,
        ),
        CampoTexto(etiqueta: 'Nota (opcional)', controller: _nota, maxLines: 2),
        FormSeccion(
          'Productos',
          accion: TextButton.icon(
            onPressed: () => setState(() => _lineas.add(_Linea())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar'),
          ),
        ),
        ..._lineas.asMap().entries.map((entry) {
          final i = entry.key;
          final linea = entry.value;
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
                        valor: linea.producto,
                        opciones: _productos,
                        etiquetaDe: (p) => p.nombre,
                        subtituloDe: (p) => p.sku,
                        hintBuscar: 'Buscar producto',
                        onChanged: (p) => _onProductoElegido(linea, p),
                      ),
                    ),
                    if (_lineas.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() {
                          linea.dispose();
                          _lineas.removeAt(i);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: linea.cantidad,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cantidad', isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: linea.costo,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Costo unitario', isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _moneda.format(_total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
