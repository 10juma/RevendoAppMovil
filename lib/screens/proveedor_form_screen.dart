import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';

/// Alta/edición de un proveedor — mismos campos que el modal de
/// /Admin/Proveedores en la web.
class ProveedorFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Proveedor? proveedor;
  const ProveedorFormScreen({super.key, required this.sesion, this.proveedor});

  @override
  State<ProveedorFormScreen> createState() => _ProveedorFormScreenState();
}

class _ProveedorFormScreenState extends State<ProveedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.proveedor?.nombre);
  late final _contacto = TextEditingController(text: widget.proveedor?.contacto);
  late final _telefono = TextEditingController(text: widget.proveedor?.telefono);
  late final _email = TextEditingController(text: widget.proveedor?.email);
  late final _direccion = TextEditingController(text: widget.proveedor?.direccion);
  late final _notas = TextEditingController(text: widget.proveedor?.notas);
  late bool _activo = widget.proveedor?.activo ?? true;

  bool get _editando => widget.proveedor != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    _telefono.dispose();
    _email.dispose();
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final body = {
      'nombre': _nombre.text.trim(),
      'contacto': _contacto.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
      'direccion': _direccion.text.trim(),
      'notas': _notas.text.trim(),
      'activo': _activo,
    };
    if (_editando) {
      await _api.actualizarProveedor(widget.proveedor!.id, body);
    } else {
      await _api.crearProveedor(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar proveedor' : 'Nuevo proveedor',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre',
          controller: _nombre,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Escribe el nombre del proveedor' : null,
        ),
        CampoTexto(etiqueta: 'Contacto', controller: _contacto),
        CampoTexto(etiqueta: 'Teléfono', controller: _telefono, teclado: TextInputType.phone),
        CampoTexto(
          etiqueta: 'Correo',
          controller: _email,
          teclado: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
            return ok ? null : 'Ese correo no parece válido';
          },
        ),
        CampoTexto(etiqueta: 'Dirección', controller: _direccion),
        CampoTexto(etiqueta: 'Notas', controller: _notas, maxLines: 3),
        if (_editando)
          FormSwitch(
            etiqueta: 'Activo',
            valor: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
      ],
    );
  }
}
