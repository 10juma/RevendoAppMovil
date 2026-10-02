import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/almacen.dart';
import '../models/cliente.dart';
import '../models/existencia.dart';
import '../models/producto.dart';
import '../models/sesion.dart';
import '../models/venta.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/buscador_campo.dart';
import '../widgets/form_scaffold.dart';

final _moneda = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
final _entero = NumberFormat.decimalPattern('es_MX');
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

const _canalOptions = [
  DropdownMenuItem(value: 'Facebook', child: Text('Facebook')),
  DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
  DropdownMenuItem(value: 'Tienda', child: Text('Tienda')),
  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
];

class _Linea {
  Producto? producto;
  final TextEditingController cantidad = TextEditingController();
  final TextEditingController precio = TextEditingController();
  void dispose() {
    cantidad.dispose();
    precio.dispose();
  }
}

/// Alta o edición de una venta — mismos campos que el modal "Nueva venta" /
/// "Editar venta" de /Admin/Ventas en la web (sin el autocompletado de la
/// lista de precios activa ni los grupos de alias — el precio se escribe a
/// mano). Editar concilia las existencias en el servidor, igual que la web;
/// el estado de entrega no se toca desde aquí (eso es de Rutas de reparto).
class VentaFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Venta? venta;
  const VentaFormScreen({super.key, required this.sesion, this.venta});

  @override
  State<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends State<VentaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _fechaSel = DateTime.now();
  Cliente? _clienteSel;
  String? _almacenId;
  String _canal = 'Tienda';
  bool _pagada = true;
  bool _entregado = true;
  final _nota = TextEditingController();
  final List<_Linea> _lineas = [_Linea()];

  bool _cargando = true;
  List<Cliente> _clientes = [];
  List<Almacen> _almacenes = [];
  List<Producto> _productos = [];
  List<Existencia> _existencias = [];

  bool get _editando => widget.venta != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final clientes = await _api.listarClientes();
      final almacenes = await _api.listarAlmacenes();
      final productos = await _api.listarProductos();
      final existencias = await _api.listarExistencias();
      if (!mounted) return;
      setState(() {
        _clientes = clientes
            .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
            .where((c) => c.activo || c.id == widget.venta?.clienteId)
            .toList();
        _almacenes = almacenes
            .map((e) => Almacen.fromJson(e as Map<String, dynamic>))
            .where((a) => a.activo || a.id == widget.venta?.almacenId)
            .toList();
        _productos = productos
            .map((e) => Producto.fromJson(e as Map<String, dynamic>))
            .where((p) => p.tipo != 'Insumo' && (p.activo || (widget.venta?.items.any((i) => i.productoId == p.id) ?? false)))
            .toList();
        _existencias = existencias
            .map((e) => Existencia.fromJson(e as Map<String, dynamic>))
            .toList();
        _precargarVenta();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Al editar, rellena el formulario con lo que ya tiene la venta.
  void _precargarVenta() {
    final v = widget.venta;
    if (v == null) return;

    _fechaSel = v.fecha.toLocal();
    _almacenId = v.almacenId;
    _canal = v.canal;
    _pagada = v.pagada;
    _nota.text = v.nota ?? '';
    for (final c in _clientes) {
      if (c.id == v.clienteId) _clienteSel = c;
    }

    for (final l in _lineas) {
      l.dispose();
    }
    _lineas
      ..clear()
      ..addAll(v.items.map((i) {
        final linea = _Linea();
        for (final p in _productos) {
          if (p.id == i.productoId) linea.producto = p;
        }
        linea.cantidad.text = i.cantidad.toString();
        linea.precio.text = i.precioUnitario.toStringAsFixed(2);
        return linea;
      }));
  }

  /// Cuánto hay del producto de [linea] en el almacén elegido, restando lo
  /// que ya usan las DEMÁS líneas de esta misma venta — mismo criterio que
  /// actualizarStockInfoVenta() en /Admin/Ventas (ahí es "cantidadYaEnCarrito").
  double? _disponiblePara(_Linea linea) {
    final producto = linea.producto;
    if (producto == null || _almacenId == null) return null;

    final existencia = _existencias.where(
      (e) => e.productoId == producto.id && e.almacenId == _almacenId,
    );
    var enAlmacen = existencia.isEmpty ? 0.0 : existencia.first.cantidad;

    // Al editar, lo que esta venta ya descontó del mismo almacén vuelve a
    // estar disponible (el servidor lo concilia al guardar).
    final original = widget.venta;
    if (original != null && original.almacenId == _almacenId) {
      for (final i in original.items) {
        if (i.productoId == producto.id) enAlmacen += i.cantidad;
      }
    }

    var usadoEnOtras = 0.0;
    for (final l in _lineas) {
      if (identical(l, linea)) continue;
      if (l.producto?.id != producto.id) continue;
      usadoEnOtras += double.tryParse(l.cantidad.text.trim()) ?? 0;
    }

    return (enAlmacen - usadoEnOtras).clamp(0, double.infinity);
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
      if (producto != null && producto.precioVenta != null && linea.precio.text.isEmpty) {
        linea.precio.text = producto.precioVenta!.toStringAsFixed(2);
      }
    });
  }

  Future<void> _guardar() async {
    final items = <Map<String, dynamic>>[];
    for (final l in _lineas) {
      final cantidad = double.tryParse(l.cantidad.text.trim());
      final precio = double.tryParse(l.precio.text.trim());
      if (l.producto == null || cantidad == null || cantidad <= 0 || precio == null || precio < 0) {
        continue;
      }
      items.add({'productoId': l.producto!.id, 'cantidad': cantidad, 'precioUnitario': precio});
    }
    if (items.isEmpty) {
      throw ApiException('Agrega al menos un producto con cantidad y precio');
    }

    final body = {
      'fechaVenta': _fechaSel.toIso8601String(),
      'clienteId': _clienteSel?.id,
      'almacenId': _almacenId,
      'canal': _canal,
      'pagada': _pagada,
      'entregado': _entregado,
      'nota': _nota.text.trim(),
      'items': items,
    };
    if (_editando) {
      await _api.actualizarVenta(widget.venta!.id, body);
    } else {
      await _api.crearVenta(body);
    }
  }

  double get _total {
    var total = 0.0;
    for (final l in _lineas) {
      final cantidad = double.tryParse(l.cantidad.text.trim()) ?? 0;
      final precio = double.tryParse(l.precio.text.trim()) ?? 0;
      total += cantidad * precio;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: Text(_editando ? 'Editar venta' : 'Nueva venta')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return FormScaffold(
      titulo: _editando ? 'Editar venta' : 'Nueva venta',
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
        BuscadorCampo<Cliente>(
          etiqueta: 'Cliente',
          valor: _clienteSel,
          opciones: _clientes,
          etiquetaDe: (c) => c.nombre,
          subtituloDe: (c) => c.telefono,
          permiteVacio: true,
          etiquetaVacio: 'Público general',
          textoSinSeleccion: 'Público general',
          hintBuscar: 'Buscar cliente',
          onChanged: (c) => setState(() => _clienteSel = c),
        ),
        FormDropdown<String>(
          etiqueta: 'Almacén',
          valor: _almacenId,
          items: _almacenes
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
              .toList(),
          onChanged: (v) => setState(() => _almacenId = v!),
          validator: (v) => v == null ? 'Selecciona un almacén' : null,
        ),
        FormDropdown<String>(
          etiqueta: 'Canal',
          valor: _canal,
          items: _canalOptions,
          onChanged: (v) => setState(() => _canal = v!),
        ),
        FormSwitch(
          etiqueta: 'Pagada',
          valor: _pagada,
          onChanged: (v) => setState(() => _pagada = v),
        ),
        if (!_editando)
          FormSwitch(
            etiqueta: 'Ya se entregó',
            valor: _entregado,
            onChanged: (v) => setState(() => _entregado = v),
          ),
        if (!_editando && !_entregado)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text(
              'Quedará Pendiente para asignar repartidor desde Rutas de reparto.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
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
                        controller: linea.precio,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio unitario', isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (_disponiblePara(linea) != null) ...[
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final disponible = _disponiblePara(linea)!;
                    final cantidad = double.tryParse(linea.cantidad.text.trim()) ?? 0;
                    final restante = disponible - cantidad;
                    final unidad = linea.producto!.unidadMedida.toLowerCase();
                    return Text(
                      cantidad > 0
                          ? 'Disponible: ${_entero.format(disponible)} $unidad — quedarán ${_entero.format(restante)} $unidad'
                          : 'Disponible: ${_entero.format(disponible)} $unidad',
                      style: TextStyle(
                        fontSize: 12,
                        color: restante < 0 ? AppColors.error : AppColors.textMuted,
                        fontWeight: restante < 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }),
                ],
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
