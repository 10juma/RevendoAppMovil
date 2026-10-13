import 'package:flutter/material.dart';

import '../theme.dart';

/// Panel que sube desde abajo (el mismo estilo de "Vincular cliente") para
/// capturar algo corto sin salir de la pantalla — por ejemplo agregar un
/// producto a una venta o compra. [contenido] se reconstruye con `setPanel`
/// para refrescar lo que depende de los campos (existencias, subtotal…);
/// cierra con `Navigator.pop(ctx, valor)` y ese valor es el resultado.
Future<T?> mostrarPanelInferior<T>({
  required BuildContext context,
  required String titulo,
  required Widget Function(BuildContext ctx, StateSetter setPanel) contenido,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setPanel) => Padding(
        // Sube con el teclado para que los campos no queden tapados.
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 16),
                contenido(ctx, setPanel),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Aviso de error dentro de un panel (mismo aspecto que en los formularios).
class ErrorPanel extends StatelessWidget {
  final String mensaje;
  const ErrorPanel(this.mensaje, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
      child: Text(mensaje, style: const TextStyle(color: AppColors.error)),
    );
  }
}
