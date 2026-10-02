import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';

/// Alta/edición de un cliente — mismos campos que el modal de
/// /Admin/Clientes en la web.
class ClienteFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Cliente? cliente;
  const ClienteFormScreen({super.key, required this.sesion, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final _email = TextEditingController(text: widget.cliente?.email);
  late final _direccion = TextEditingController(text: widget.cliente?.direccion);
  late final _notas = TextEditingController(text: widget.cliente?.notas);
  late bool _activo = widget.cliente?.activo ?? true;

  bool get _editando => widget.cliente != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _email.dispose();
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final body = {
      'nombre': _nombre.text.trim(),
      'telefono': _telefono.text.trim(),
      'email': _email.text.trim(),
      'direccion': _direccion.text.trim(),
      'notas': _notas.text.trim(),
      'activo': _activo,
    };
    if (_editando) {
      await _api.actualizarCliente(widget.cliente!.id, body);
    } else {
      await _api.crearCliente(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar cliente' : 'Nuevo cliente',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre',
          controller: _nombre,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Escribe el nombre del cliente' : null,
        ),
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
