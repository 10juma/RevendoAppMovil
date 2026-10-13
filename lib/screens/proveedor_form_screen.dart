import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/panel_inferior.dart';

/// Alta/edición de un proveedor en un panel — mismos campos que el modal de
/// /Admin/Proveedores en la web. Regresa `true` si se guardó.
Future<bool> abrirFormularioProveedor(BuildContext context, Sesion sesion, {Proveedor? proveedor}) async {
  final api = ApiClient(token: sesion.token);
  final editando = proveedor != null;
  final nombre = TextEditingController(text: proveedor?.nombre);
  final contacto = TextEditingController(text: proveedor?.contacto);
  final telefono = TextEditingController(text: proveedor?.telefono);
  final email = TextEditingController(text: proveedor?.email);
  final direccion = TextEditingController(text: proveedor?.direccion);
  final notas = TextEditingController(text: proveedor?.notas);
  var activo = proveedor?.activo ?? true;

  final guardado = await mostrarPanelFormulario(
    context: context,
    titulo: editando ? 'Editar proveedor' : 'Nuevo proveedor',
    campos: (setPanel) => [
      CampoTexto(
        etiqueta: 'Nombre',
        controller: nombre,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre del proveedor' : null,
      ),
      CampoTexto(etiqueta: 'Contacto', controller: contacto),
      CampoTexto(etiqueta: 'Teléfono', controller: telefono, teclado: TextInputType.phone),
      CampoTexto(
        etiqueta: 'Correo',
        controller: email,
        teclado: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
          return ok ? null : 'Ese correo no parece válido';
        },
      ),
      CampoTexto(etiqueta: 'Dirección', controller: direccion),
      CampoTexto(etiqueta: 'Notas', controller: notas, maxLines: 3),
      if (editando)
        FormSwitch(etiqueta: 'Activo', valor: activo, onChanged: (v) => setPanel(() => activo = v)),
    ],
    onGuardar: () async {
      final body = {
        'nombre': nombre.text.trim(),
        'contacto': contacto.text.trim(),
        'telefono': telefono.text.trim(),
        'email': email.text.trim(),
        'direccion': direccion.text.trim(),
        'notas': notas.text.trim(),
        'activo': activo,
      };
      if (editando) {
        await api.actualizarProveedor(proveedor.id, body);
      } else {
        await api.crearProveedor(body);
      }
    },
  );

  liberarControladores([nombre, contacto, telefono, email, direccion, notas]);
  return guardado;
}
