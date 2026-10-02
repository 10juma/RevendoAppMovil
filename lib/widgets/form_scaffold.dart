import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme.dart';

/// Armazón genérico para los formularios de crear/editar — cada pantalla
/// solo aporta sus campos y la llamada a guardar; esto se encarga del botón
/// de guardar, el loading mientras guarda, mostrar errores del servidor y
/// regresar `true` al cerrar cuando sí se guardó (para que la lista detrás
/// sepa que debe recargar).
class FormScaffold extends StatefulWidget {
  final String titulo;
  final List<Widget> children;
  final Future<void> Function() onGuardar;
  final String textoBoton;
  final Widget? accionExtra;
  final GlobalKey<FormState>? formKey;

  const FormScaffold({
    super.key,
    required this.titulo,
    required this.children,
    required this.onGuardar,
    this.textoBoton = 'Guardar',
    this.accionExtra,
    this.formKey,
  });

  @override
  State<FormScaffold> createState() => _FormScaffoldState();
}

class _FormScaffoldState extends State<FormScaffold> {
  bool _guardando = false;
  String? _error;

  Future<void> _guardar() async {
    if (widget.formKey != null && !widget.formKey!.currentState!.validate()) {
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.onGuardar();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje == 'sesion_expirada'
            ? 'Tu sesión expiró — vuelve a entrar.'
            : e.mensaje;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo guardar — revisa tu internet.';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [if (widget.accionExtra != null) widget.accionExtra!],
      ),
      body: Form(
        key: widget.formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            ],
            ...widget.children,
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.textoBoton),
          ),
        ),
      ),
    );
  }
}

/// Título de sección dentro de un formulario (p. ej. "Receta", "Productos").
class FormSeccion extends StatelessWidget {
  final String texto;
  final Widget? accion;
  const FormSeccion(this.texto, {super.key, this.accion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            texto,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Campo de texto estándar de los formularios — mismo padding/estilo en
/// todos lados, con menos repetición por pantalla.
class CampoTexto extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? teclado;
  final int maxLines;
  final bool obscureText;

  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.validator,
    this.teclado,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: teclado,
        maxLines: obscureText ? 1 : maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: etiqueta),
      ),
    );
  }
}

/// Dropdown estándar de los formularios (Tipo, Rol, Categoría, etc.).
class FormDropdown<T> extends StatelessWidget {
  final String etiqueta;
  final T? valor;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const FormDropdown({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}

/// Switch con etiqueta a la izquierda, mismo criterio en todos los
/// formularios para los campos bool (Activo, EsPrincipal, Pagada, etc.).
class FormSwitch extends StatelessWidget {
  final String etiqueta;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const FormSwitch({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(etiqueta),
      value: valor,
      onChanged: onChanged,
    );
  }
}
