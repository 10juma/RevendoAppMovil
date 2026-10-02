import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/producto.dart';
import '../models/sesion.dart';
import '../widgets/filter_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'producto_form_screen.dart';

final _moneda = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

/// Mismo contenido y mismos filtros que /Admin/Productos en el panel web
/// (Buscar, Tipo, Activo), de solo lectura.
class ProductosScreen extends StatefulWidget {
  final Sesion sesion;
  const ProductosScreen({super.key, required this.sesion});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Producto>>();

  String _buscar = '';
  String? _tipo; // null = todos, si no "Reventa" | "Producido" | "Insumo"
  bool? _activo;

  bool get _hayFiltros => _tipo != null || _activo != null;

  bool _filtro(Producto p) {
    if (_tipo != null && p.tipo != _tipo) return false;
    if (_activo != null && p.activo != _activo) return false;
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return p.nombre.toLowerCase().contains(b) ||
        (p.sku?.toLowerCase().contains(b) ?? false) ||
        (p.marca?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    String? tipo = _tipo;
    bool? activo = _activo;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar productos',
      onLimpiar: () => setState(() {
        _tipo = null;
        _activo = null;
      }),
      onAplicar: () => setState(() {
        _tipo = tipo;
        _activo = activo;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Tipo',
                valor: tipo,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'Reventa', child: Text('Reventa directa')),
                  DropdownMenuItem(
                    value: 'Producido',
                    child: Text('Producido (con receta)'),
                  ),
                  DropdownMenuItem(
                    value: 'Insumo',
                    child: Text('Insumo / materia prima'),
                  ),
                ],
                onChanged: (v) => setSheet(() => tipo = v),
              ),
              FiltroTriEstado(
                etiqueta: 'Activo',
                valor: activo,
                onChanged: (v) => setSheet(() => activo = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario([Producto? producto]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(sesion: widget.sesion, producto: producto),
      ),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Producto>(
      key: _listKey,
      titulo: 'Productos',
      icono: IconosMenu.productos,
      sesion: widget.sesion,
      vacioTexto: 'No tienes productos registrados.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por nombre, SKU o marca',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add_rounded),
      ),
      fetch: (api) async {
        final data = await api.listarProductos();
        return data
            .map((e) => Producto.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, p) => InkWell(
        onTap: () => _abrirFormulario(p),
        child: InfoCard(
          titulo: p.nombre,
          subtitulo: [
            p.tipo,
            p.unidadMedida,
            if (p.marca != null) p.marca!,
          ].join(' · '),
          trailing: p.precioVenta != null ? _moneda.format(p.precioVenta) : '—',
          inactivo: !p.activo,
          filas: [
            if (p.costo != null) MapEntry('Costo', _moneda.format(p.costo)),
            if (p.categoria != null) MapEntry('Categoría', p.categoria!),
            if (p.sku != null) MapEntry('SKU', p.sku!),
            if (p.receta.isNotEmpty)
              MapEntry('Receta', '${p.receta.length} insumo(s)'),
          ],
        ),
      ),
    );
  }
}
