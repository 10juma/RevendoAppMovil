import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/panel_inferior.dart';

/// Alta/edición de un cliente en un panel — mismos campos que el modal de
/// /Admin/Clientes en la web. Regresa `true` si se guardó.
Future<bool> abrirFormularioCliente(BuildContext context, Sesion sesion, {Cliente? cliente}) async {
  final api = ApiClient(token: sesion.token);
  final editando = cliente != null;
  final nombre = TextEditingController(text: cliente?.nombre);
  final telefono = TextEditingController(text: cliente?.telefono);
  final email = TextEditingController(text: cliente?.email);
  final direccion = TextEditingController(text: cliente?.direccion);
  final notas = TextEditingController(text: cliente?.notas);
  var activo = cliente?.activo ?? true;

  final guardado = await mostrarPanelFormulario(
    context: context,
    titulo: editando ? 'Editar cliente' : 'Nuevo cliente',
    campos: (setPanel) => [
      CampoTexto(
        etiqueta: 'Nombre',
        controller: nombre,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre del cliente' : null,
      ),
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
        'telefono': telefono.text.trim(),
        'email': email.text.trim(),
        'direccion': direccion.text.trim(),
        'notas': notas.text.trim(),
        'activo': activo,
      };
      if (editando) {
        await api.actualizarCliente(cliente.id, body);
      } else {
        await api.crearCliente(body);
      }
    },
  );

  liberarControladores([nombre, telefono, email, direccion, notas]);
  return guardado;
}
