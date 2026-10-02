import 'package:flutter/material.dart';

import '../models/negocio.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';

/// Editar el perfil del negocio — mismos campos que /Admin/Negocio en la web
/// (el logo se sigue subiendo solo desde ahí por ahora).
class NegocioFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Negocio negocio;
  const NegocioFormScreen({super.key, required this.sesion, required this.negocio});

  @override
  State<NegocioFormScreen> createState() => _NegocioFormScreenState();
}

class _NegocioFormScreenState extends State<NegocioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.negocio.nombre);
  late final _descripcion = TextEditingController(text: widget.negocio.descripcion);
  late final _direccion = TextEditingController(text: widget.negocio.direccion);
  late final _telefono = TextEditingController(text: widget.negocio.telefono);
  late final _email = TextEditingController(text: widget.negocio.emailContacto);
  late final _facebook = TextEditingController(text: widget.negocio.facebook);
  late final _instagram = TextEditingController(text: widget.negocio.instagram);
  late final _whatsApp = TextEditingController(text: widget.negocio.whatsApp);

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _direccion.dispose();
    _telefono.dispose();
    _email.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _whatsApp.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    await _api.actualizarNegocio({
      'nombre': _nombre.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'direccion': _direccion.text.trim(),
      'telefono': _telefono.text.trim(),
      'emailContacto': _email.text.trim(),
      'facebook': _facebook.text.trim(),
      'instagram': _instagram.text.trim(),
      'whatsApp': _whatsApp.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: 'Editar mi negocio',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre del negocio',
          controller: _nombre,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Escribe el nombre de tu negocio' : null,
        ),
        CampoTexto(etiqueta: 'Descripción', controller: _descripcion, maxLines: 3),
        CampoTexto(etiqueta: 'Dirección', controller: _direccion),
        CampoTexto(etiqueta: 'Teléfono', controller: _telefono, teclado: TextInputType.phone),
        CampoTexto(
          etiqueta: 'Correo de contacto',
          controller: _email,
          teclado: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
            return ok ? null : 'Ese correo no parece válido';
          },
        ),
        CampoTexto(etiqueta: 'Facebook', controller: _facebook),
        CampoTexto(etiqueta: 'Instagram', controller: _instagram),
        CampoTexto(etiqueta: 'WhatsApp', controller: _whatsApp),
      ],
    );
  }
}
