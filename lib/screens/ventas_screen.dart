import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/cliente.dart';
import '../models/sesion.dart';
import '../models/venta.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/buscador_campo.dart';
import '../widgets/filter_bar.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/info_card.dart';
import '../widgets/simple_list_screen.dart';
import 'venta_detalle_screen.dart';
import 'venta_form_screen.dart';

final _moneda = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);
String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Mismo contenido y mismos filtros (Cliente, Canal, Almacén, Desde/Hasta)
/// que /Admin/Ventas en el panel web, de solo lectura. Visible para Admin y
/// Vendedor (mismos roles que ya autoriza /api/ventas).
class VentasScreen extends StatefulWidget {
  final Sesion sesion;
  const VentasScreen({super.key, required this.sesion});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _listKey = GlobalKey<SimpleListScreenState<Venta>>();

  String _buscar = '';
  String? _cliente;
  String? _canal;
  String? _almacen;
  DateTime? _desde;
  DateTime? _hasta;
  List<String> _clientesDisponibles = [];
  List<String> _canalesDisponibles = [];
  List<String> _almacenesDisponibles = [];
  List<Cliente> _clientes = [];

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final data = await _api.listarClientes();
      if (!mounted) return;
      setState(() {
        _clientes = data
            .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
            .where((c) => c.activo)
            .toList();
      });
    } catch (_) {
      // Si falla, el modal de vincular simplemente sale sin opciones — no es
      // crítico para ver la lista de ventas.
    }
  }

  bool get _hayFiltros =>
      _cliente != null ||
      _canal != null ||
      _almacen != null ||
      _desde != null ||
      _hasta != null;

  bool _filtro(Venta v) {
    if (_cliente != null && (v.clienteNombre ?? 'Público general') != _cliente) {
      return false;
    }
    if (_canal != null && v.canal != _canal) return false;
    if (_almacen != null && v.almacenNombre != _almacen) return false;
    if (_desde != null && v.fecha.isBefore(_desde!)) return false;
    if (_hasta != null &&
        v.fecha.isAfter(_hasta!.add(const Duration(days: 1)))) {
      return false;
    }
    if (_buscar.trim().isEmpty) return true;
    final b = _buscar.trim().toLowerCase();
    return (v.clienteNombre?.toLowerCase().contains(b) ?? false) ||
        v.almacenNombre.toLowerCase().contains(b) ||
        (v.nota?.toLowerCase().contains(b) ?? false);
  }

  void _abrirFiltros() {
    String? cliente = _cliente;
    String? canal = _canal;
    String? almacen = _almacen;
    DateTime? desde = _desde;
    DateTime? hasta = _hasta;
    showFiltrosSheet(
      context,
      titulo: 'Filtrar ventas',
      onLimpiar: () => setState(() {
        _cliente = null;
        _canal = null;
        _almacen = null;
        _desde = null;
        _hasta = null;
      }),
      onAplicar: () => setState(() {
        _cliente = cliente;
        _canal = canal;
        _almacen = almacen;
        _desde = desde;
        _hasta = hasta;
      }),
      children: [
        StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            children: [
              FiltroDropdown<String?>(
                etiqueta: 'Cliente',
                valor: cliente,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._clientesDisponibles.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setSheet(() => cliente = v),
              ),
              FiltroDropdown<String?>(
                etiqueta: 'Canal',
                valor: canal,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._canalesDisponibles.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setSheet(() => canal = v),
              ),
              FiltroDropdown<String?>(
                etiqueta: 'Almacén',
                valor: almacen,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._almacenesDisponibles.map(
                    (a) => DropdownMenuItem(value: a, child: Text(a)),
                  ),
                ],
                onChanged: (v) => setSheet(() => almacen = v),
              ),
              FiltroFecha(
                etiqueta: 'Desde',
                valor: desde,
                onChanged: (v) => setSheet(() => desde = v),
              ),
              FiltroFecha(
                etiqueta: 'Hasta',
                valor: hasta,
                onChanged: (v) => setSheet(() => hasta = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VentaFormScreen(sesion: widget.sesion)),
    );
    if (guardado == true) _listKey.currentState?.reload();
  }

  Future<void> _abrirDetalle(Venta v) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VentaDetalleScreen(sesion: widget.sesion, venta: v)),
    );
    if (cambio == true) _listKey.currentState?.reload();
  }

  /// Mismo modal "Vincular cliente" de /Admin/Ventas — liga la venta a un
  /// cliente existente, o da de alta uno nuevo al vuelo.
  Future<void> _abrirVincularCliente(Venta v) async {
    Cliente? clienteSel;
    for (final c in _clientes) {
      if (c.nombre == v.clienteNombre) {
        clienteSel = c;
        break;
      }
    }

    var esNuevo = _clientes.isEmpty;
    final nombreNuevo = TextEditingController();
    final telefonoNuevo = TextEditingController();
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vincular cliente',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                  const SizedBox(height: 16),
                  if (error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(error!, style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                  if (_clientes.isNotEmpty)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Cliente existente')),
                        ButtonSegment(value: true, label: Text('Cliente nuevo')),
                      ],
                      selected: {esNuevo},
                      onSelectionChanged: (s) => setSheet(() => esNuevo = s.first),
                    ),
                  const SizedBox(height: 14),
                  if (!esNuevo)
                    BuscadorCampo<Cliente>(
                      etiqueta: 'Cliente',
                      valor: clienteSel,
                      opciones: _clientes,
                      etiquetaDe: (c) => c.nombre,
                      subtituloDe: (c) => c.telefono,
                      hintBuscar: 'Buscar cliente',
                      onChanged: (c) => setSheet(() => clienteSel = c),
                    )
                  else ...[
                    CampoTexto(etiqueta: 'Nombre del cliente nuevo', controller: nombreNuevo),
                    CampoTexto(etiqueta: 'Teléfono (opcional)', controller: telefonoNuevo, teclado: TextInputType.phone),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _api.vincularCliente(
                            v.id,
                            clienteId: esNuevo ? null : clienteSel?.id,
                            clienteNuevoNombre: esNuevo ? nombreNuevo.text.trim() : null,
                            clienteNuevoTelefono: esNuevo ? telefonoNuevo.text.trim() : null,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _listKey.currentState?.reload();
                          _cargarClientes();
                        } on ApiException catch (e) {
                          setSheet(() => error = e.mensaje);
                        } catch (_) {
                          setSheet(() => error = 'No se pudo guardar — revisa tu internet.');
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nombreNuevo.dispose();
    telefonoNuevo.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleListScreen<Venta>(
      key: _listKey,
      titulo: 'Ventas',
      icono: IconosMenu.ventas,
      sesion: widget.sesion,
      vacioTexto: 'No tienes ventas registradas.',
      filtro: _filtro,
      filtroBar: FilterBar(
        busquedaHint: 'Buscar por cliente, almacén o nota',
        busqueda: _buscar,
        onBusquedaChanged: (v) => setState(() => _buscar = v),
        onFiltrosTap: _abrirFiltros,
        filtrosActivos: _hayFiltros,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        child: const Icon(Icons.add_rounded),
      ),
      onCargado: (items) {
        setState(() {
          _clientesDisponibles =
              items.map((v) => v.clienteNombre ?? 'Público general').toSet().toList()
                ..sort();
          _canalesDisponibles = items.map((v) => v.canal).toSet().toList()..sort();
          _almacenesDisponibles =
              items.map((v) => v.almacenNombre).toSet().toList()..sort();
        });
      },
      fetch: (api) async {
        final data = await api.listarVentas();
        return data
            .map((e) => Venta.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      itemBuilder: (context, v) => InkWell(
        onTap: () => _abrirDetalle(v),
        child: InfoCard(
          titulo: v.clienteNombre ?? 'Público general',
          subtitulo: '${v.almacenNombre} · ${v.canal} · ${_fecha(v.fecha)}',
          trailing: _moneda.format(v.total),
          trailingColor: v.pagada ? AppColors.text : AppColors.error,
          filas: [
            MapEntry('Pagada', v.pagada ? 'Sí' : 'No'),
            MapEntry('Entrega', v.estadoEntrega),
            if (v.repartidorNombre != null)
              MapEntry('Repartidor', v.repartidorNombre!),
          ],
          acciones: [
            TextButton.icon(
              onPressed: () => _abrirVincularCliente(v),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Cliente'),
            ),
            TextButton.icon(
              onPressed: () => compartirTicketVenta(context, widget.sesion, v),
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Compartir'),
            ),
          ],
        ),
      ),
    );
  }
}
