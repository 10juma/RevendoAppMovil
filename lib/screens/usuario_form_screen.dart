import 'package:flutter/material.dart';

import '../models/sesion.dart';
import '../models/usuario.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';

const _rolOptions = [
  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
  DropdownMenuItem(value: 'Vendedor', child: Text('Vendedor')),
  DropdownMenuItem(value: 'Repartidor', child: Text('Repartidor')),
];

/// Alta/edición de un usuario del equipo — mismos campos que el modal de
/// /Admin/Equipo en la web.
class UsuarioFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Usuario? usuario;
  const UsuarioFormScreen({super.key, required this.sesion, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario?.nombre);
  late final _email = TextEditingController(text: widget.usuario?.email);
  final _password = TextEditingController();
  late String _rol = widget.usuario?.rol ?? 'Vendedor';
  late bool _activo = widget.usuario?.activo ?? true;

  bool get _editando => widget.usuario != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final body = {
      'nombre': _nombre.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text.isEmpty ? null : _password.text,
      'rol': _rol,
      'activo': _activo,
    };
    if (_editando) {
      await _api.actualizarUsuario(widget.usuario!.id, body);
    } else {
      await _api.crearUsuario(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar usuario' : 'Nuevo usuario',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre',
          controller: _nombre,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
        ),
        CampoTexto(
          etiqueta: 'Correo',
          controller: _email,
          teclado: TextInputType.emailAddress,
          validator: (v) {
            final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '');
            return ok ? null : 'Escribe un correo válido';
          },
        ),
        CampoTexto(
          etiqueta: _editando ? 'Nueva contraseña (opcional)' : 'Contraseña',
          controller: _password,
          obscureText: true,
          validator: (v) {
            if (_editando && (v == null || v.isEmpty)) return null;
            if (v == null || v.length < 6) return 'Debe tener al menos 6 caracteres';
            return null;
          },
        ),
        FormDropdown<String>(
          etiqueta: 'Rol',
          valor: _rol,
          items: _rolOptions,
          onChanged: (v) => setState(() => _rol = v!),
        ),
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
