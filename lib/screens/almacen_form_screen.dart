import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/panel_inferior.dart';

const _tipoOptions = [
  DropdownMenuItem(value: 'Bodega', child: Text('Bodega')),
  DropdownMenuItem(value: 'Tienda', child: Text('Tienda / punto de venta')),
  DropdownMenuItem(value: 'Vehiculo', child: Text('Vehículo / ruta')),
];

/// Alta/edición de un almacén en un panel — mismos campos que el modal de
/// /Admin/Almacenes en la web. Regresa `true` si se guardó.
Future<bool> abrirFormularioAlmacen(BuildContext context, Sesion sesion, {Almacen? almacen}) async {
  final api = ApiClient(token: sesion.token);
  final editando = almacen != null;
  final nombre = TextEditingController(text: almacen?.nombre);
  final direccion = TextEditingController(text: almacen?.direccion);
  final telefono = TextEditingController(text: almacen?.telefono);
  var tipo = almacen?.tipo ?? 'Bodega';
  var esPrincipal = almacen?.esPrincipal ?? false;
  var activo = almacen?.activo ?? true;

  final guardado = await mostrarPanelFormulario(
    context: context,
    titulo: editando ? 'Editar almacén' : 'Nuevo almacén',
    campos: (setPanel) => [
      CampoTexto(
        etiqueta: 'Nombre',
        controller: nombre,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre del almacén' : null,
      ),
      FormDropdown<String>(
        etiqueta: 'Tipo',
        valor: tipo,
        items: _tipoOptions,
        onChanged: (v) => setPanel(() => tipo = v!),
      ),
      CampoTexto(etiqueta: 'Dirección', controller: direccion),
      CampoTexto(etiqueta: 'Teléfono', controller: telefono, teclado: TextInputType.phone),
      FormSwitch(
        etiqueta: 'Almacén principal',
        valor: esPrincipal,
        onChanged: (v) => setPanel(() => esPrincipal = v),
      ),
      if (editando)
        FormSwitch(etiqueta: 'Activo', valor: activo, onChanged: (v) => setPanel(() => activo = v)),
    ],
    onGuardar: () async {
      final body = {
        'nombre': nombre.text.trim(),
        'tipo': tipo,
        'direccion': direccion.text.trim(),
        'telefono': telefono.text.trim(),
        'esPrincipal': esPrincipal,
        'activo': activo,
      };
      if (editando) {
        await api.actualizarAlmacen(almacen.id, body);
      } else {
        await api.crearAlmacen(body);
      }
    },
  );

  liberarControladores([nombre, direccion, telefono]);
  return guardado;
}
