import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../widgets/form_scaffold.dart';

const _tipoOptions = [
  DropdownMenuItem(value: 'Bodega', child: Text('Bodega')),
  DropdownMenuItem(value: 'Tienda', child: Text('Tienda / punto de venta')),
  DropdownMenuItem(value: 'Vehiculo', child: Text('Vehículo / ruta')),
];

/// Alta/edición de un almacén — mismos campos que el modal de
/// /Admin/Almacenes en la web.
class AlmacenFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Almacen? almacen;
  const AlmacenFormScreen({super.key, required this.sesion, this.almacen});

  @override
  State<AlmacenFormScreen> createState() => _AlmacenFormScreenState();
}

class _AlmacenFormScreenState extends State<AlmacenFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.almacen?.nombre);
  late final _direccion = TextEditingController(text: widget.almacen?.direccion);
  late final _telefono = TextEditingController(text: widget.almacen?.telefono);
  late String _tipo = widget.almacen?.tipo ?? 'Bodega';
  late bool _esPrincipal = widget.almacen?.esPrincipal ?? false;
  late bool _activo = widget.almacen?.activo ?? true;

  bool get _editando => widget.almacen != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final body = {
      'nombre': _nombre.text.trim(),
      'tipo': _tipo,
      'direccion': _direccion.text.trim(),
      'telefono': _telefono.text.trim(),
      'esPrincipal': _esPrincipal,
      'activo': _activo,
    };
    if (_editando) {
      await _api.actualizarAlmacen(widget.almacen!.id, body);
    } else {
      await _api.crearAlmacen(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar almacén' : 'Nuevo almacén',
      formKey: _formKey,
      onGuardar: _guardar,
      children: [
        CampoTexto(
          etiqueta: 'Nombre',
          controller: _nombre,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Escribe el nombre del almacén' : null,
        ),
        FormDropdown<String>(
          etiqueta: 'Tipo',
          valor: _tipo,
          items: _tipoOptions,
          onChanged: (v) => setState(() => _tipo = v!),
        ),
        CampoTexto(etiqueta: 'Dirección', controller: _direccion),
        CampoTexto(etiqueta: 'Teléfono', controller: _telefono, teclado: TextInputType.phone),
        FormSwitch(
          etiqueta: 'Almacén principal',
          valor: _esPrincipal,
          onChanged: (v) => setState(() => _esPrincipal = v),
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
