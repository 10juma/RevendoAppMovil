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

final _entero = NumberFormat.decimalPattern('es_MX');

/// Producir un producto a partir de su receta — mismo modal "Producir" de
/// /Admin/Produccion en la web: consume los insumos y da de alta el
/// producto terminado en existencias.
class ProducirScreen extends StatefulWidget {
  final Sesion sesion;
  const ProducirScreen({super.key, required this.sesion});

  @override
  State<ProducirScreen> createState() => _ProducirScreenState();
}

class _ProducirScreenState extends State<ProducirScreen> {
  final _formKey = GlobalKey<FormState>();
  Producto? _productoSel;
  String? _almacenId;
  final _cantidad = TextEditingController();

  bool _cargando = true;
  List<Producto> _producibles = [];
  List<Almacen> _almacenes = [];
  List<Existencia> _existencias = [];

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final productos = await _api.listarProductos();
      final almacenes = await _api.listarAlmacenes();
      final existencias = await _api.listarExistencias();
      if (!mounted) return;
      setState(() {
        _producibles = productos
            .map((e) => Producto.fromJson(e as Map<String, dynamic>))
            .where((p) => p.tipo == 'Producido' && p.activo && p.receta.isNotEmpty)
            .toList();
        _almacenes = almacenes
            .map((e) => Almacen.fromJson(e as Map<String, dynamic>))
            .where((a) => a.activo)
            .toList();
        _existencias = existencias
            .map((e) => Existencia.fromJson(e as Map<String, dynamic>))
            .toList();
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Cuánto hay de un insumo en el almacén elegido — 0 si no hay registro.
  double _tieneInsumo(String insumoId) {
    if (_almacenId == null) return 0;
    final existencia = _existencias.where(
      (e) => e.productoId == insumoId && e.almacenId == _almacenId,
    );
    return existencia.isEmpty ? 0 : existencia.first.cantidad;
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    await _api.producir({
      'productoId': _productoSel?.id,
      'almacenId': _almacenId,
      'cantidad': double.parse(_cantidad.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producir')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_producibles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Producir')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No tienes productos de tipo "Producido" con receta todavía — agrégala desde Productos antes de producir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return FormScaffold(
      titulo: 'Producir',
      textoBoton: 'Producir',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        BuscadorCampo<Producto>(
          etiqueta: 'Producto a producir',
          valor: _productoSel,
          opciones: _producibles,
          etiquetaDe: (p) => p.nombre,
          hintBuscar: 'Buscar producto',
          onChanged: (p) => setState(() => _productoSel = p),
          validator: (p) => p == null ? 'Selecciona qué producto vas a producir' : null,
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
          etiqueta: 'Cantidad a producir',
          controller: _cantidad,
          teclado: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            final n = double.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0) return 'La cantidad debe ser mayor a cero';
            return null;
          },
        ),
        if (_productoSel != null)
          AnimatedBuilder(
            animation: _cantidad,
            builder: (context, _) {
              final cantidadProducir = double.tryParse(_cantidad.text.trim()) ?? 0;
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
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._productoSel!.receta.map((r) {
                      final necesitas = r.cantidad * cantidadProducir;
                      final tienes = _tieneInsumo(r.insumoId);
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
      ],
    );
  }
}
