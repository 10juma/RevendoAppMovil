import 'package:flutter/material.dart';

import '../theme.dart';

/// Hoja inferior con buscador — misma idea que FilterBar/showFiltrosSheet
/// pero para elegir UN registro de un catálogo potencialmente largo
/// (Producto, Cliente, Proveedor). Filtra en memoria sobre la lista ya
/// cargada, sin golpear la API otra vez.
Future<T?> mostrarBuscador<T>({
  required BuildContext context,
  required String titulo,
  required List<T> opciones,
  required String Function(T item) etiquetaDe,
  String? Function(T item)? subtituloDe,
  String hintBuscar = 'Buscar...',
  String textoVacio = 'Sin resultados.',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _BuscadorSheet<T>(
      titulo: titulo,
      opciones: opciones,
      etiquetaDe: etiquetaDe,
      subtituloDe: subtituloDe,
      hintBuscar: hintBuscar,
      textoVacio: textoVacio,
    ),
  );
}

class _BuscadorSheet<T> extends StatefulWidget {
  final String titulo;
  final List<T> opciones;
  final String Function(T) etiquetaDe;
  final String? Function(T)? subtituloDe;
  final String hintBuscar;
  final String textoVacio;

  const _BuscadorSheet({
    required this.titulo,
    required this.opciones,
    required this.etiquetaDe,
    required this.subtituloDe,
    required this.hintBuscar,
    required this.textoVacio,
  });

  @override
  State<_BuscadorSheet<T>> createState() => _BuscadorSheetState<T>();
}

class _BuscadorSheetState<T> extends State<_BuscadorSheet<T>> {
  final _controller = TextEditingController();
  late List<T> _filtrados = widget.opciones;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filtrar(String v) {
    final b = v.trim().toLowerCase();
    setState(() {
      _filtrados = b.isEmpty
          ? widget.opciones
          : widget.opciones.where((o) {
              return widget.etiquetaDe(o).toLowerCase().contains(b) ||
                  (widget.subtituloDe?.call(o)?.toLowerCase().contains(b) ?? false);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _filtrar,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hintBuscar,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _filtrar('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: _filtrados.isEmpty
                  ? Center(
                      child: Text(
                        widget.textoVacio,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filtrados.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (ctx, i) {
                        final item = _filtrados[i];
                        final subtitulo = widget.subtituloDe?.call(item);
                        return ListTile(
                          title: Text(widget.etiquetaDe(item)),
                          subtitle: subtitulo == null || subtitulo.isEmpty
                              ? null
                              : Text(subtitulo),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de formulario tipo "dropdown" pero que abre el buscador de arriba
/// en vez de una lista desplegable corta — para catálogos grandes
/// (Producto, Cliente, Proveedor). Se integra con Form/validator igual que
/// FormDropdown.
class BuscadorCampo<T> extends FormField<T> {
  BuscadorCampo({
    super.key,
    required String etiqueta,
    required T? valor,
    required List<T> opciones,
    required String Function(T) etiquetaDe,
    String? Function(T)? subtituloDe,
    required ValueChanged<T?> onChanged,
    super.validator,
    String hintBuscar = 'Buscar...',
    String textoVacioLista = 'Sin resultados.',
    String textoSinSeleccion = 'Toca para elegir',
    bool permiteVacio = false,
    String etiquetaVacio = 'Ninguno',
  }) : super(
          initialValue: valor,
          builder: (state) {
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                // Objetos en vez de T? directo: así "cerré la hoja sin elegir"
                // (el Future resuelve en null) se distingue de "elegí Ninguno"
                // (resuelve en _Opcion(null)) — si no, cerrar sin elegir
                // borraría la selección que ya había.
                final resultado = await mostrarBuscador<_Opcion<T>>(
                  context: state.context,
                  titulo: etiqueta,
                  opciones: [
                    if (permiteVacio) const _Opcion(null),
                    ...opciones.map((o) => _Opcion(o)),
                  ],
                  etiquetaDe: (o) => o.valor == null ? etiquetaVacio : etiquetaDe(o.valor as T),
                  subtituloDe: (o) => o.valor == null ? null : subtituloDe?.call(o.valor as T),
                  hintBuscar: hintBuscar,
                  textoVacio: textoVacioLista,
                );
                if (resultado == null) return;
                state.didChange(resultado.valor);
                onChanged(resultado.valor);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: etiqueta,
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.search_rounded, size: 20),
                ),
                child: Text(
                  state.value != null ? etiquetaDe(state.value as T) : textoSinSeleccion,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: state.value != null ? AppColors.text : AppColors.textMuted,
                  ),
                ),
              ),
            );
          },
        );
}

/// Envuelve el valor elegido (que puede ser null, cuando permiteVacio) para
/// distinguirlo de "cerré la hoja sin tocar nada", que también resuelve el
/// Future del bottom sheet en null.
class _Opcion<T> {
  final T? valor;
  const _Opcion(this.valor);
}
