import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/almacen.dart';
import '../models/existencia.dart';
import '../models/producto.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/buscador_campo.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/panel_inferior.dart';

final _entero = NumberFormat.decimalPattern('es_MX');

Producto? _buscarProducto(List<Producto> lista, String? id) {
  if (id == null) return null;
  for (final p in lista) {
    if (p.id == id) return p;
  }
  return null;
}

/// Ajustar la existencia de un producto en un almacén, en un panel — mismo
/// modal "Ajustar existencia" de /Admin/Existencias en la web: pone la
/// cantidad en un valor absoluto, el servidor calcula el delta y registra el
/// movimiento. En una existencia nueva arranca en el almacén principal, y al
/// elegir producto y almacén dice cuánto hay y cuánto quedaría.
/// Regresa `true` si se guardó.
Future<bool> abrirAjustarExistencia(BuildContext context, Sesion sesion, {Existencia? existencia}) async {
  final api = ApiClient(token: sesion.token);
  var productoId = existencia?.productoId;
  var almacenId = existencia?.almacenId;
  final cantidad = TextEditingController(text: existencia?.cantidad.toStringAsFixed(2));
  final nota = TextEditingController();

  var productos = <Producto>[];
  var almacenes = <Almacen>[];
  var existencias = <Existencia>[];

  final carga = () async {
    final p = await api.listarProductos();
    final a = await api.listarAlmacenes();
    final e = await api.listarExistencias();
    productos = p.map((x) => Producto.fromJson(x as Map<String, dynamic>)).toList();
    almacenes = a
        .map((x) => Almacen.fromJson(x as Map<String, dynamic>))
        .where((x) => x.activo || x.id == existencia?.almacenId)
        .toList();
    existencias = e.map((x) => Existencia.fromJson(x as Map<String, dynamic>)).toList();
    if (almacenId == null) {
      final principal = almacenes.where((x) => x.esPrincipal && x.activo);
      if (principal.isNotEmpty) almacenId = principal.first.id;
    }
  }();

  double? hayEnSistema() {
    if (productoId == null || almacenId == null) return null;
    final e = existencias.where((x) => x.productoId == productoId && x.almacenId == almacenId);
    return e.isEmpty ? 0 : e.first.cantidad;
  }

  final guardado = await mostrarPanelFormulario(
    context: context,
    titulo: 'Ajustar existencia',
    carga: carga,
    campos: (setPanel) => [
      BuscadorCampo<Producto>(
        etiqueta: 'Producto',
        valor: _buscarProducto(productos, productoId),
        opciones: productos,
        etiquetaDe: (p) => p.nombre,
        subtituloDe: (p) => p.sku,
        hintBuscar: 'Buscar producto',
        onChanged: (p) => setPanel(() => productoId = p?.id),
        validator: (p) => p == null ? 'Selecciona un producto' : null,
      ),
      FormDropdown<String>(
        etiqueta: 'Almacén',
        valor: almacenId,
        items: almacenes.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))).toList(),
        onChanged: (v) => setPanel(() => almacenId = v),
        validator: (v) => v == null ? 'Selecciona un almacén' : null,
      ),
      CampoTexto(
        etiqueta: 'Cantidad nueva',
        controller: cantidad,
        teclado: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final n = double.tryParse(v?.trim() ?? '');
          if (n == null || n < 0) return 'La cantidad no puede ser negativa';
          return null;
        },
      ),
      AnimatedBuilder(
        animation: cantidad,
        builder: (context, _) {
          final hay = hayEnSistema();
          final producto = _buscarProducto(productos, productoId);
          if (hay == null || producto == null) return const SizedBox.shrink();
          final unidad = producto.unidadMedida.toLowerCase();
          final nueva = double.tryParse(cantidad.text.trim());
          final delta = nueva == null ? null : nueva - hay;
          final signo = delta == null ? '' : (delta > 0 ? '+' : '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              nueva == null
                  ? 'Hay ${_entero.format(hay)} $unidad en el sistema.'
                  : 'Hay ${_entero.format(hay)} $unidad — con el ajuste quedarán ${_entero.format(nueva)} $unidad ($signo${_entero.format(delta)}).',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          );
        },
      ),
      CampoTexto(etiqueta: 'Nota (opcional)', controller: nota, maxLines: 2),
    ],
    onGuardar: () async {
      await api.ajustarExistencia({
        'productoId': productoId,
        'almacenId': almacenId,
        'cantidadNueva': double.parse(cantidad.text.trim()),
        'nota': nota.text.trim(),
      });
    },
  );

  liberarControladores([cantidad, nota]);
  return guardado;
}
