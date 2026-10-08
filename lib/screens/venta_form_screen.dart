import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/almacen.dart';
import '../models/cliente.dart';
import '../models/existencia.dart';
import '../models/lista_precios.dart';
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

/// Lo que se elige en el selector de producto: un producto suelto o un grupo de
/// productos que comparten el mismo "nombre para mostrar" en la lista de precios
/// activa (son intercambiables: se descuenta del que tenga existencia).
class _OpcionProducto {
  final String etiqueta;
  final List<Producto> productos;
  final bool grupo;
  _OpcionProducto(this.etiqueta, this.productos, {this.grupo = false});
}

class _Linea {
  _OpcionProducto? opcion;
  /// Al editar: el producto que la venta ya tenía, para conservarlo si dentro
  /// de un grupo sigue alcanzando la existencia.
  String? productoOriginalId;
  final TextEditingController cantidad = TextEditingController();
  final TextEditingController precio = TextEditingController();
  void dispose() {
    cantidad.dispose();
    precio.dispose();
  }
}

/// Alta o edición de una venta — mismos campos que el modal "Nueva venta" /
/// "Editar venta" de /Admin/Ventas en la web, incluida la lista de precios
/// activa (precio especial, descuento y nombre para mostrar; los productos con
/// el mismo nombre se agrupan y se descuenta del que tenga existencia). El
/// precio sigue siendo editable a mano. Editar concilia las existencias en el
/// servidor, igual que la web;
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
  ListaPrecios? _lista;
  Map<String, ListaPreciosItem> _itemsLista = {};
  List<_OpcionProducto> _opciones = [];

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
      // Si no hay lista activa (o la API aún no la expone) se vende a precio de catálogo.
      final listas = await _api.listarListaPreciosActiva().catchError((_) => <dynamic>[]);
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
        _lista = listas.isEmpty ? null : ListaPrecios.fromJson(listas.first as Map<String, dynamic>);
        _itemsLista = {for (final i in _lista?.items ?? <ListaPreciosItem>[]) i.productoId: i};
        _armarOpciones();
        _precargarVenta();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Arma lo que ofrece el selector: cada producto con su nombre para mostrar
  /// (si la lista activa se lo cambia) y, en lugar de los productos que
  /// comparten un mismo nombre, una sola opción de grupo — igual que la web.
  void _armarOpciones() {
    final idsPorAlias = <String, Set<String>>{};
    for (final it in _itemsLista.values) {
      final alias = it.nombreMostrado?.trim();
      if (alias == null || alias.isEmpty) continue;
      idsPorAlias.putIfAbsent(alias, () => <String>{}).add(it.productoId);
    }

    final enGrupo = <String>{};
    final opciones = <_OpcionProducto>[];
    idsPorAlias.forEach((alias, ids) {
      if (ids.length < 2) return;
      enGrupo.addAll(ids);
      final productos = _productos.where((p) => ids.contains(p.id)).toList();
      if (productos.isNotEmpty) opciones.add(_OpcionProducto(alias, productos, grupo: true));
    });

    for (final p in _productos) {
      if (enGrupo.contains(p.id)) continue;
      final alias = _itemsLista[p.id]?.nombreMostrado?.trim();
      opciones.add(_OpcionProducto(alias == null || alias.isEmpty ? p.nombre : alias, [p]));
    }

    opciones.sort((a, b) => a.etiqueta.toLowerCase().compareTo(b.etiqueta.toLowerCase()));
    _opciones = opciones;
  }

  /// Precio que se prellena: el precio especial de la lista (o el de catálogo)
  /// menos el descuento de la lista, si lo tiene. Sin precio en ningún lado: 0.
  double _precioDe(Producto p) {
    final catalogo = p.precioVenta ?? 0;
    final item = _itemsLista[p.id];
    if (item == null) return catalogo;
    final base = item.precioLista ?? catalogo;
    final d = item.descuentoPorcentaje;
    return d == null ? base : double.parse((base * (1 - d / 100)).toStringAsFixed(2));
  }

  /// Texto bajo la línea: qué promo de la lista aplica al producto elegido.
  String? _promoDe(_OpcionProducto op) {
    if (op.grupo) {
      return 'Se descontará del producto ligado a "${op.etiqueta}" que tenga existencia disponible.';
    }
    final item = _itemsLista[op.productos.first.id];
    if (item == null || _lista == null) return null;
    final partes = <String>[
      if (item.precioLista != null) 'precio especial',
      if (item.descuentoPorcentaje != null) '-${_pct(item.descuentoPorcentaje!)}%',
    ];
    return partes.isEmpty ? null : '${_lista!.nombre}: ${partes.join(' ')}';
  }

  static String _pct(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);

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
        for (final o in _opciones) {
          if (o.productos.any((p) => p.id == i.productoId)) linea.opcion = o;
        }
        linea.productoOriginalId = i.productoId;
        linea.cantidad.text = i.cantidad.toString();
        linea.precio.text = i.precioUnitario.toStringAsFixed(2);
        return linea;
      }));
  }

  /// Existencia del producto en el almacén elegido. Al editar, lo que esta
  /// venta ya descontó del mismo almacén vuelve a estar disponible (el servidor
  /// lo concilia al guardar).
  double _enAlmacen(String productoId) {
    final existencia = _existencias.where(
      (e) => e.productoId == productoId && e.almacenId == _almacenId,
    );
    var enAlmacen = existencia.isEmpty ? 0.0 : existencia.first.cantidad;

    final original = widget.venta;
    if (original != null && original.almacenId == _almacenId) {
      for (final i in original.items) {
        if (i.productoId == productoId) enAlmacen += i.cantidad;
      }
    }
    return enAlmacen;
  }

  /// Cuánto hay de lo elegido en [linea] en el almacén, restando lo que ya
  /// usan las DEMÁS líneas de esta misma venta — mismo criterio que
  /// actualizarStockInfoVenta() en /Admin/Ventas (ahí es "cantidadYaEnCarrito").
  /// Para un grupo es lo disponible entre todas sus variantes.
  double? _disponiblePara(_Linea linea) {
    final op = linea.opcion;
    if (op == null || _almacenId == null) return null;

    final ids = op.productos.map((p) => p.id).toSet();
    var enAlmacen = 0.0;
    for (final id in ids) {
      enAlmacen += _enAlmacen(id);
    }

    var usadoEnOtras = 0.0;
    for (final l in _lineas) {
      if (identical(l, linea)) continue;
      final otra = l.opcion;
      if (otra == null || !otra.productos.any((p) => ids.contains(p.id))) continue;
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

  /// Cambiar el producto siempre refresca el precio al de la lista activa (o al
  /// de catálogo) del producto nuevo — sigue siendo editable a mano.
  void _onProductoElegido(_Linea linea, _OpcionProducto? opcion) {
    setState(() {
      linea.opcion = opcion;
      linea.precio.text = opcion == null ? '' : _precioDe(opcion.productos.first).toStringAsFixed(2);
    });
  }

  Future<void> _guardar() async {
    final validas = <(_Linea, double, double)>[];
    for (final l in _lineas) {
      final cantidad = double.tryParse(l.cantidad.text.trim());
      final precio = double.tryParse(l.precio.text.trim());
      if (l.opcion == null || cantidad == null || cantidad <= 0 || precio == null || precio < 0) {
        continue;
      }
      validas.add((l, cantidad, precio));
    }

    // Lo ya comprometido por productos sueltos; después, cada línea de grupo
    // elige la variante con más existencia que alcance a cubrirla.
    final usado = <String, double>{};
    for (final (l, cantidad, _) in validas) {
      if (!l.opcion!.grupo) {
        final id = l.opcion!.productos.first.id;
        usado[id] = (usado[id] ?? 0) + cantidad;
      }
    }

    final items = <Map<String, dynamic>>[];
    for (final (l, cantidad, precio) in validas) {
      final op = l.opcion!;
      String productoId;
      if (!op.grupo) {
        productoId = op.productos.first.id;
      } else {
        double libre(Producto p) => _enAlmacen(p.id) - (usado[p.id] ?? 0);
        final candidatos = [...op.productos]..sort((a, b) => libre(b).compareTo(libre(a)));
        final original = op.productos.where((p) => p.id == l.productoOriginalId);
        final elegido = original.isNotEmpty && libre(original.first) >= cantidad
            ? original.first
            : candidatos.where((p) => libre(p) >= cantidad).firstOrNull;
        if (elegido == null) {
          throw ApiException(
            'Ninguno de los productos ligados a "${op.etiqueta}" tiene existencia suficiente en ese almacén.',
          );
        }
        productoId = elegido.id;
        usado[productoId] = (usado[productoId] ?? 0) + cantidad;
      }
      items.add({'productoId': productoId, 'cantidad': cantidad, 'precioUnitario': precio});
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
        if (_lista != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Usando la lista de precios activa "${_lista!.nombre}" como base — puedes editar cualquier precio.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ),
        ..._lineas.asMap().entries.map((entry) {
          final i = entry.key;
          final linea = entry.value;
          return Container(
            key: ObjectKey(linea),
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
                      child: BuscadorCampo<_OpcionProducto>(
                        etiqueta: 'Producto',
                        valor: linea.opcion,
                        opciones: _opciones,
                        etiquetaDe: (o) => o.etiqueta,
                        subtituloDe: (o) => o.grupo ? 'Variantes ligadas' : o.productos.first.sku,
                        hintBuscar: 'Buscar producto',
                        onChanged: (o) => _onProductoElegido(linea, o),
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
                    final unidad = linea.opcion!.productos.first.unidadMedida.toLowerCase();
                    final de = linea.opcion!.grupo ? 'Disponible entre variantes ligadas' : 'Disponible';
                    return Text(
                      cantidad > 0
                          ? '$de: ${_entero.format(disponible)} $unidad — quedarán ${_entero.format(restante)} $unidad'
                          : '$de: ${_entero.format(disponible)} $unidad',
                      style: TextStyle(
                        fontSize: 12,
                        color: restante < 0 ? AppColors.error : AppColors.textMuted,
                        fontWeight: restante < 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }),
                ],
                if (linea.opcion != null && _promoDe(linea.opcion!) != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _promoDe(linea.opcion!)!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
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
