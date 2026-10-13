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

/// Producir un producto a partir de su receta, en un panel — mismo modal
/// "Producir" de /Admin/Produccion en la web: consume los insumos y da de
/// alta el producto terminado en existencias. Arranca en el almacén
/// principal y muestra cuánto se va a consumir contra lo que hay.
/// Regresa `true` si se produjo.
Future<bool> abrirProducir(BuildContext context, Sesion sesion) async {
  final api = ApiClient(token: sesion.token);
  Producto? productoSel;
  String? almacenId;
  final cantidad = TextEditingController();

  var producibles = <Producto>[];
  var almacenes = <Almacen>[];
  var existencias = <Existencia>[];

  final carga = () async {
    final p = await api.listarProductos();
    final a = await api.listarAlmacenes();
    final e = await api.listarExistencias();
    producibles = p
        .map((x) => Producto.fromJson(x as Map<String, dynamic>))
        .where((x) => x.tipo == 'Producido' && x.activo && x.receta.isNotEmpty)
        .toList();
    almacenes = a.map((x) => Almacen.fromJson(x as Map<String, dynamic>)).where((x) => x.activo).toList();
    existencias = e.map((x) => Existencia.fromJson(x as Map<String, dynamic>)).toList();
    final principal = almacenes.where((x) => x.esPrincipal);
    if (principal.isNotEmpty) almacenId = principal.first.id;
  }();

  /// Cuánto hay de un insumo en el almacén elegido — 0 si no hay registro.
  double tieneInsumo(String insumoId) {
    if (almacenId == null) return 0;
    final e = existencias.where((x) => x.productoId == insumoId && x.almacenId == almacenId);
    return e.isEmpty ? 0 : e.first.cantidad;
  }

  final producido = await mostrarPanelFormulario(
    context: context,
    titulo: 'Producir',
    textoBoton: 'Producir',
    carga: carga,
    ocultarGuardar: () => producibles.isEmpty,
    campos: (setPanel) {
      if (producibles.isEmpty) {
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No tienes productos de tipo "Producido" con receta todavía — agrégala desde Productos antes de producir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ];
      }
      return [
        BuscadorCampo<Producto>(
          etiqueta: 'Producto a producir',
          valor: productoSel,
          opciones: producibles,
          etiquetaDe: (p) => p.nombre,
          hintBuscar: 'Buscar producto',
          onChanged: (p) => setPanel(() => productoSel = p),
          validator: (p) => p == null ? 'Selecciona qué producto vas a producir' : null,
        ),
        FormDropdown<String>(
          etiqueta: 'Almacén',
          valor: almacenId,
          items: almacenes.map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre))).toList(),
          onChanged: (v) => setPanel(() => almacenId = v),
          validator: (v) => v == null ? 'Selecciona un almacén' : null,
        ),
        CampoTexto(
          etiqueta: 'Cantidad a producir',
          controller: cantidad,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final n = double.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0) return 'La cantidad debe ser mayor a cero';
            return null;
          },
        ),
        if (productoSel != null)
          AnimatedBuilder(
            animation: cantidad,
            builder: (context, _) {
              final cantidadProducir = double.tryParse(cantidad.text.trim()) ?? 0;
              if (cantidadProducir <= 0) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vas a consumir',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    ...productoSel!.receta.map((r) {
                      final necesitas = r.cantidad * cantidadProducir;
                      final tienes = tieneInsumo(r.insumoId);
                      final faltante = tienes < necesitas;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.insumoNombre,
                                style: const TextStyle(fontSize: 13, color: AppColors.text),
                              ),
                            ),
                            Text(
                              'Necesitas ${_entero.format(necesitas)} · Tienes ${_entero.format(tienes)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: faltante ? AppColors.error : AppColors.successText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
      ];
    },
    onGuardar: () async {
      await api.producir({
        'productoId': productoSel?.id,
        'almacenId': almacenId,
        'cantidad': double.parse(cantidad.text.trim()),
      });
    },
  );

  liberarControladores([cantidad]);
  return producido;
}
