import 'package:flutter/material.dart';

import '../models/lista_precios.dart';
import '../models/producto.dart';
import '../models/sesion.dart';
import '../widgets/lista_precios_widget.dart';
import 'api_client.dart';
import 'compartir_imagen.dart';

String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Comparte una lista de precios como imagen, con el mismo formato que el
/// ticket de venta. Cada producto de la lista sale con su precio final (el
/// precio especial o el de catálogo, menos el descuento) y, si es menor al
/// normal, el precio de antes. Los productos con el mismo nombre y precio
/// (variantes ligadas) salen una sola vez, y los que no tienen precio no salen.
Future<void> compartirListaPrecios(BuildContext context, Sesion sesion, ListaPrecios lista) async {
  final mensajes = ScaffoldMessenger.of(context);
  mensajes.showSnackBar(const SnackBar(content: Text('Preparando la lista…'), duration: Duration(seconds: 2)));

  final List<Producto> productos;
  try {
    final data = await ApiClient(token: sesion.token).listarProductos();
    productos = data.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    mensajes.showSnackBar(const SnackBar(content: Text('No se pudo preparar la lista — revisa tu internet.')));
    return;
  }
  if (!context.mounted) return;

  final catalogo = {for (final p in productos) p.id: p.precioVenta};
  final vistos = <String>{};
  final lineas = <ListaPreciosLinea>[];

  for (final item in lista.items) {
    final normal = catalogo[item.productoId];
    final base = item.precioLista ?? normal;
    if (base == null || base <= 0) continue;

    final descuento = item.descuentoPorcentaje;
    final precio = descuento == null ? base : double.parse((base * (1 - descuento / 100)).toStringAsFixed(2));
    final alias = item.nombreMostrado?.trim();
    final nombre = (alias == null || alias.isEmpty) ? item.producto : alias;

    if (!vistos.add('$nombre|${precio.toStringAsFixed(2)}')) continue;
    lineas.add(ListaPreciosLinea(
      nombre: nombre,
      precio: precio,
      precioAntes: normal != null && normal > precio ? normal : null,
      descuentoPorcentaje: descuento,
    ));
  }

  if (lineas.isEmpty) {
    mensajes.showSnackBar(const SnackBar(content: Text('Esta lista no tiene productos con precio para compartir.')));
    return;
  }
  lineas.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

  await compartirWidgetComoImagen(
    context: context,
    nombreArchivo: 'lista_precios_${lista.id.substring(0, 8)}',
    textoCompartir: '${sesion.tenantNombre} — ${lista.nombre}',
    widget: ListaPreciosWidget(
      negocioNombre: sesion.tenantNombre,
      nombreLista: lista.nombre,
      fecha: _fecha(DateTime.now()),
      lineas: lineas,
    ),
  );
}
