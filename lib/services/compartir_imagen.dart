import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renderiza [widget] fuera de pantalla (vía Overlay, para no tocar el
/// árbol de la pantalla que lo pide), lo captura como PNG y abre la hoja
/// nativa de compartir — así cualquier pantalla puede "compartir como
/// imagen" un ticket/voucher sin duplicar la lógica de captura.
Future<void> compartirWidgetComoImagen({
  required BuildContext context,
  required Widget widget,
  required String nombreArchivo,
  String? textoCompartir,
}) async {
  final key = GlobalKey();
  final overlay = Overlay.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -10000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: key, child: widget),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Dos frames para asegurar que el layout/paint ya terminó antes de capturar.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imagen = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final dir = await getTemporaryDirectory();
    final archivo = File('${dir.path}/$nombreArchivo.png');
    await archivo.writeAsBytes(bytes);

    // En iPad, UIActivityViewController truena si no se le da un punto de
    // origen para el popover — en iPhone este dato simplemente se ignora.
    Rect? origen;
    if (context.mounted) {
      // El contexto puede ser el de un sliver (tarjeta dentro de una lista),
      // cuyo render object no es un RenderBox — por eso no se castea a ciegas.
      final render = context.findRenderObject();
      final box = render is RenderBox ? render : null;
      if (box != null && box.hasSize) {
        origen = box.localToGlobal(Offset.zero) & box.size;
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(archivo.path)],
        text: textoCompartir,
        sharePositionOrigin: origen,
      ),
    );
  } finally {
    entry.remove();
  }
}
