import 'package:flutter/material.dart';

import '../services/api_client.dart';
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

/// Panel con un formulario completo: campos, errores del servidor y botón de
/// guardar con spinner. Es el equivalente en panel de FormScaffold.
///
/// - [campos] se reconstruye con `setPanel` (para dropdowns, switches y textos
///   que dependen de lo capturado); solo se arma cuando [carga] ya terminó.
/// - [carga] (opcional): catálogos que se piden con el panel ya abierto; mientras
///   tanto se ve un indicador y el botón no se puede usar.
/// - [ocultarGuardar]: para paneles que solo muestran un aviso (p. ej. sin recetas).
/// Regresa `true` si se guardó, para que quien lo abrió recargue su lista.
Future<bool> mostrarPanelFormulario({
  required BuildContext context,
  required String titulo,
  required List<Widget> Function(StateSetter setPanel) campos,
  required Future<void> Function() onGuardar,
  String textoBoton = 'Guardar',
  Future<void>? carga,
  bool Function()? ocultarGuardar,
}) async {
  final formKey = GlobalKey<FormState>();
  var guardando = false;
  var cargando = carga != null;
  String? error;
  StateSetter? refrescar;

  void avisar() {
    try {
      refrescar?.call(() {});
    } catch (_) {
      // El panel ya se cerró.
    }
  }

  carga?.then((_) {
    cargando = false;
    avisar();
  }, onError: (_) {
    cargando = false;
    error = 'No se pudieron cargar los datos — revisa tu internet.';
    avisar();
  });

  final resultado = await mostrarPanelInferior<bool>(
    context: context,
    titulo: titulo,
    contenido: (ctx, setPanel) {
      refrescar = setPanel;
      final sinGuardar = ocultarGuardar?.call() ?? false;
      return Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null) ErrorPanel(error!),
            if (cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...campos(setPanel),
            if (!cargando && !sinGuardar) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setPanel(() {
                            guardando = true;
                            error = null;
                          });
                          try {
                            await onGuardar();
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } on ApiException catch (e) {
                            if (!ctx.mounted) return;
                            setPanel(() {
                              error = e.mensaje == 'sesion_expirada'
                                  ? 'Tu sesión expiró — vuelve a entrar.'
                                  : e.mensaje;
                              guardando = false;
                            });
                          } catch (_) {
                            if (!ctx.mounted) return;
                            setPanel(() {
                              error = 'No se pudo guardar — revisa tu internet.';
                              guardando = false;
                            });
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(textoBoton),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  refrescar = null;
  return resultado == true;
}

/// Libera controladores de texto de un panel ya cerrado. Hay que esperar: el
/// Future del panel se resuelve al cerrarlo, pero la animación de salida sigue
/// unos 250 ms y sus campos aún se reconstruyen — liberarlos antes truena con
/// "TextEditingController was used after being disposed".
void liberarControladores(Iterable<ChangeNotifier> controladores) {
  final lista = controladores.toList();
  Future.delayed(const Duration(milliseconds: 500), () {
    for (final c in lista) {
      c.dispose();
    }
  });
}
