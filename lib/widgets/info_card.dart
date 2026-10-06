import 'package:flutter/material.dart';

import '../theme.dart';

/// Tarjeta genérica reutilizada por todas las pantallas de solo lectura
/// (Productos, Almacenes, Compras, Ventas, etc.) — mismo estilo visual que
/// ya usan Dashboard y Reportes, para no repetir el mismo Container en cada
/// pantalla nueva.
class InfoCard extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final String? trailing;
  final Color? trailingColor;
  final List<MapEntry<String, String>> filas;
  final bool inactivo;
  final List<Widget> acciones;

  /// Texto libre (p. ej. la nota de una venta) que se muestra debajo de las filas, a lo más 2 líneas.
  final String? nota;

  const InfoCard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.trailingColor,
    this.filas = const [],
    this.inactivo = false,
    this.acciones = const [],
    this.nota,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Opacity(
        opacity: inactivo ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitulo != null && subtitulo!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitulo!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      trailing!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: trailingColor ?? AppColors.text,
                      ),
                    ),
                  ),
              ],
            ),
            if (filas.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              ...filas.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        f.key,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          f.value,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (nota != null && nota!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                nota!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: acciones),
            ],
          ],
        ),
      ),
    );
  }
}
