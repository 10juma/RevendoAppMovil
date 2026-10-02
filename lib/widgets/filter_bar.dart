import 'package:flutter/material.dart';

import '../theme.dart';

/// Barra de una sola fila — buscador + botón de filtros con ícono — igual
/// criterio en todas las pantallas nuevas (mismos filtros que ya tiene cada
/// página en el panel web, adaptados a un bottom sheet en vez de un panel).
class FilterBar extends StatefulWidget {
  final String busquedaHint;
  final String busqueda;
  final ValueChanged<String>? onBusquedaChanged;
  final VoidCallback? onFiltrosTap;
  final bool filtrosActivos;
  // Algunas páginas de la web (Compras, Gastos, Ventas, Rutas) no tienen
  // campo de texto libre, solo filtros por catálogo/fecha — en esos casos
  // se oculta el buscador y el botón de filtros ocupa toda la fila.
  final bool mostrarBusqueda;

  const FilterBar({
    super.key,
    this.busquedaHint = '',
    this.busqueda = '',
    this.onBusquedaChanged,
    this.onFiltrosTap,
    this.filtrosActivos = false,
    this.mostrarBusqueda = true,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.busqueda,
  );

  @override
  void didUpdateWidget(FilterBar old) {
    super.didUpdateWidget(old);
    // Solo lo pisamos si cambió por fuera (p. ej. "Limpiar" en el sheet de
    // filtros) — si viene del propio onChanged de aquí abajo, ya coincide.
    if (widget.busqueda != _controller.text) {
      _controller.text = widget.busqueda;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botonFiltros = widget.onFiltrosTap == null
        ? null
        : Stack(
            clipBehavior: Clip.none,
            children: [
              widget.mostrarBusqueda
                  ? OutlinedButton(
                      onPressed: widget.onFiltrosTap,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(42, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: widget.onFiltrosTap,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Filtros'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
              if (widget.filtrosActivos)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: widget.mostrarBusqueda
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _controller,
                      onChanged: widget.onBusquedaChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.busquedaHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: widget.busqueda.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => widget.onBusquedaChanged?.call(''),
                              ),
                      ),
                    ),
                  ),
                ),
                if (botonFiltros != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(width: 42, height: 42, child: botonFiltros),
                ],
              ],
            )
          : (botonFiltros ?? const SizedBox.shrink()),
    );
  }
}

/// Hoja inferior estándar para los filtros avanzados de cada pantalla —
/// mismo estilo que ya usa el selector de período del Dashboard.
Future<void> showFiltrosSheet(
  BuildContext context, {
  required String titulo,
  required List<Widget> children,
  required VoidCallback onLimpiar,
  required VoidCallback onAplicar,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      onLimpiar();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...children,
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onAplicar();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Fila "etiqueta + Dropdown" reutilizada dentro de las hojas de filtro.
class FiltroDropdown<T> extends StatelessWidget {
  final String etiqueta;
  final T? valor;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FiltroDropdown({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: valor,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Fila "etiqueta + switch" reutilizada dentro de las hojas de filtro, para
/// filtros de 3 estados (Sí / No / Todos) como FiltroActivo.
class FiltroTriEstado extends StatelessWidget {
  final String etiqueta;
  final bool? valor;
  final ValueChanged<bool?> onChanged;
  final String etiquetaSi;
  final String etiquetaNo;

  const FiltroTriEstado({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
    this.etiquetaSi = 'Sí',
    this.etiquetaNo = 'No',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<bool?>(
            segments: [
              const ButtonSegment(value: null, label: Text('Todos')),
              ButtonSegment(value: true, label: Text(etiquetaSi)),
              ButtonSegment(value: false, label: Text(etiquetaNo)),
            ],
            selected: {valor},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

String _fechaCorta(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Fila "etiqueta + botón de fecha" reutilizada para los filtros Desde/Hasta
/// (Compras, Gastos, Ventas) — mismo rango que ya tienen esas páginas en la web.
class FiltroFecha extends StatelessWidget {
  final String etiqueta;
  final DateTime? valor;
  final ValueChanged<DateTime?> onChanged;

  const FiltroFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final elegida = await showDatePicker(
                context: context,
                initialDate: valor ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (elegida != null) onChanged(elegida);
            },
            child: Text(valor != null ? _fechaCorta(valor!) : 'Cualquiera'),
          ),
          if (valor != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }
}
