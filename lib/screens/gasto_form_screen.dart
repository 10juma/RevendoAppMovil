import 'package:flutter/material.dart';

import '../models/gasto.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/form_scaffold.dart';

const _categoriaOptions = [
  DropdownMenuItem(value: 'Renta', child: Text('Renta')),
  DropdownMenuItem(value: 'Servicios', child: Text('Servicios')),
  DropdownMenuItem(value: 'Nómina', child: Text('Nómina')),
  DropdownMenuItem(value: 'Transporte', child: Text('Transporte')),
  DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
  DropdownMenuItem(value: 'Mantenimiento', child: Text('Mantenimiento')),
  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
];

String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Una fila de captura del alta de varios gastos.
class _FilaGasto {
  String categoria;
  DateTime fecha;
  final descripcion = TextEditingController();
  final monto = TextEditingController();
  final nota = TextEditingController();
  _FilaGasto(this.categoria, this.fecha);

  bool get vacia =>
      descripcion.text.trim().isEmpty && monto.text.trim().isEmpty;

  void dispose() {
    descripcion.dispose();
    monto.dispose();
    nota.dispose();
  }
}

/// Alta/edición de un gasto — mismos campos que el modal de /Admin/Gastos
/// en la web. Al crear se pueden capturar varios gastos y guardarlos juntos
/// (`POST /api/gastos/varios`); al editar es un solo gasto.
class GastoFormScreen extends StatefulWidget {
  final Sesion sesion;
  final Gasto? gasto;
  const GastoFormScreen({super.key, required this.sesion, this.gasto});

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _categoria = widget.gasto?.categoria ?? 'Otro';
  late final _descripcion = TextEditingController(
    text: widget.gasto?.descripcion,
  );
  late final _monto = TextEditingController(
    text: widget.gasto != null ? widget.gasto!.monto.toStringAsFixed(2) : '',
  );
  late DateTime _fechaSel = widget.gasto?.fecha ?? DateTime.now();
  late final _nota = TextEditingController(text: widget.gasto?.nota);
  final List<_FilaGasto> _filas = [_FilaGasto('Otro', DateTime.now())];

  bool get _editando => widget.gasto != null;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void dispose() {
    _descripcion.dispose();
    _monto.dispose();
    _nota.dispose();
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  /// Como en la web, la fila nueva hereda categoría y fecha de la anterior
  /// (es común capturar varios gastos del mismo día y tipo).
  void _agregarFila() {
    final ultima = _filas.last;
    setState(() => _filas.add(_FilaGasto(ultima.categoria, ultima.fecha)));
  }

  Future<void> _elegirFechaFila(_FilaGasto fila) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: fila.fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegida != null) setState(() => fila.fecha = elegida);
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaSel,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegida != null) setState(() => _fechaSel = elegida);
  }

  Future<void> _guardar() async {
    if (!_editando) {
      final gastos = <Map<String, dynamic>>[];
      for (final f in _filas) {
        if (f.vacia) continue;
        gastos.add({
          'categoria': f.categoria,
          'descripcion': f.descripcion.text.trim(),
          'monto': double.parse(f.monto.text.trim()),
          'fecha': f.fecha.toIso8601String(),
          'nota': f.nota.text.trim(),
        });
      }
      if (gastos.isEmpty) {
        throw ApiException('Agrega al menos un gasto con descripción y monto');
      }
      await _api.crearGastos(gastos);
      return;
    }

    final body = {
      'categoria': _categoria,
      'descripcion': _descripcion.text.trim(),
      'monto': double.parse(_monto.text.trim()),
      'fecha': _fechaSel.toIso8601String(),
      'nota': _nota.text.trim(),
    };
    await _api.actualizarGasto(widget.gasto!.id, body);
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar este gasto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _api.eliminarGasto(widget.gasto!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      titulo: _editando ? 'Editar gasto' : 'Nuevos gastos',
      formKey: _formKey,
      onGuardar: _guardar,
      accionExtra: _editando
          ? IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Eliminar',
              onPressed: _eliminar,
            )
          : null,
      children: _editando ? _camposEdicion() : _camposAlta(),
    );
  }

  List<Widget> _camposAlta() {
    return [
      for (var i = 0; i < _filas.length; i++) _tarjetaFila(i, _filas[i]),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _agregarFila,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Agregar otro gasto'),
        ),
      ),
    ];
  }

  Widget _tarjetaFila(int i, _FilaGasto f) {
    // Una fila sin descripción ni monto se ignora al guardar (igual que en la
    // web); en cuanto se escribe en una, se exigen ambos campos.
    String? validarDescripcion(String? v) =>
        (v == null || v.trim().isEmpty) && !f.vacia
        ? 'Escribe en qué se gastó'
        : null;
    String? validarMonto(String? v) {
      if (f.vacia && i > 0) return null;
      final monto = double.tryParse(v?.trim() ?? '');
      if (monto == null || monto <= 0) return 'El monto debe ser mayor a cero';
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gasto ${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (_filas.length > 1)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Quitar',
                  onPressed: () => setState(() {
                    f.dispose();
                    _filas.removeAt(i);
                  }),
                ),
            ],
          ),
          FormDropdown<String>(
            etiqueta: 'Categoría',
            valor: f.categoria,
            items: _categoriaOptions,
            onChanged: (v) => setState(() => f.categoria = v!),
          ),
          CampoTexto(
            etiqueta: 'Descripción',
            controller: f.descripcion,
            validator: validarDescripcion,
          ),
          CampoTexto(
            etiqueta: 'Monto',
            controller: f.monto,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            validator: validarMonto,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(child: Text('Fecha: ${_fecha(f.fecha)}')),
                OutlinedButton(
                  onPressed: () => _elegirFechaFila(f),
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ),
          CampoTexto(etiqueta: 'Nota (opcional)', controller: f.nota),
        ],
      ),
    );
  }

  List<Widget> _camposEdicion() {
    return [
      FormDropdown<String>(
        etiqueta: 'Categoría',
        valor: _categoria,
        items: _categoriaOptions,
        onChanged: (v) => setState(() => _categoria = v!),
      ),
      CampoTexto(
        etiqueta: 'Descripción',
        controller: _descripcion,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Escribe en qué se gastó' : null,
      ),
      CampoTexto(
        etiqueta: 'Monto',
        controller: _monto,
        teclado: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final monto = double.tryParse(v?.trim() ?? '');
          if (monto == null || monto <= 0) {
            return 'El monto debe ser mayor a cero';
          }
          return null;
        },
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(child: Text('Fecha: ${_fecha(_fechaSel)}')),
            OutlinedButton(
              onPressed: _elegirFecha,
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
      CampoTexto(etiqueta: 'Nota', controller: _nota, maxLines: 3),
    ];
  }
}
