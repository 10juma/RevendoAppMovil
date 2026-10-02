import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/reporte.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../theme.dart';

/// Mismo contenido que /Admin/Reportes en el panel web, en 3 pestañas
/// (Ventas, Compras, Gastos) en vez de un selector — sin filtros de
/// cliente/proveedor/categoría todavía, siempre últimos 30 días (mismo
/// default que ya usa Revendo.Api cuando no se mandan fechas).
class ReportesScreen extends StatefulWidget {
  final Sesion sesion;

  const ReportesScreen({super.key, required this.sesion});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloConIcono(icono: IconosMenu.reportes, texto: 'Reportes'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.accentDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.accentDark,
          tabs: const [
            Tab(text: 'Ventas'),
            Tab(text: 'Compras'),
            Tab(text: 'Gastos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _VentasTab(api: _api),
          _ComprasTab(api: _api),
          _GastosTab(api: _api),
        ],
      ),
    );
  }
}

final _moneda = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 0,
);
final _entero = NumberFormat.decimalPattern('es_MX');

class _VentasTab extends StatefulWidget {
  final ApiClient api;
  const _VentasTab({required this.api});

  @override
  State<_VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends State<_VentasTab> {
  ReporteVentas? _reporte;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await widget.api.obtenerReporte('ventas');
      if (!mounted) return;
      setState(() {
        _reporte = ReporteVentas.fromJson(data);
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje == 'sesion_expirada'
            ? 'Tu sesión expiró — vuelve a entrar.'
            : e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar el reporte — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EstadoCarga(
      cargando: _cargando,
      error: _error,
      onReintentar: _cargar,
      contentBuilder: () {
        final r = _reporte!;
        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ResumenGrid(
                filas: [
                  _Stat('Ventas', '${r.totalVentas}'),
                  _Stat('Ingresos', _moneda.format(r.totalIngresos)),
                  _Stat('Ticket promedio', _moneda.format(r.ticketPromedio)),
                  _Stat('Margen total', _moneda.format(r.margenTotal)),
                ],
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Productos más vendidos'),
              if (r.productosTop.isEmpty)
                const _SinDatos('Sin ventas en este período.')
              else
                ...r.productosTop.map(
                  (p) => _FilaProducto(
                    nombre: p.nombre,
                    detalle: '${_entero.format(p.cantidad)} uds.',
                    monto: _moneda.format(p.ingresos),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ComprasTab extends StatefulWidget {
  final ApiClient api;
  const _ComprasTab({required this.api});

  @override
  State<_ComprasTab> createState() => _ComprasTabState();
}

class _ComprasTabState extends State<_ComprasTab> {
  ReporteCompras? _reporte;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await widget.api.obtenerReporte('compras');
      if (!mounted) return;
      setState(() {
        _reporte = ReporteCompras.fromJson(data);
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje == 'sesion_expirada'
            ? 'Tu sesión expiró — vuelve a entrar.'
            : e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar el reporte — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EstadoCarga(
      cargando: _cargando,
      error: _error,
      onReintentar: _cargar,
      contentBuilder: () {
        final r = _reporte!;
        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ResumenGrid(
                filas: [
                  _Stat('Compras', '${r.totalCompras}'),
                  _Stat('Gastado', _moneda.format(r.totalGastadoCompras)),
                  _Stat(
                    'Costo promedio',
                    _moneda.format(r.costoPromedioCompra),
                  ),
                  _Stat('Proveedores', '${r.proveedoresDistintos}'),
                ],
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Productos más comprados'),
              if (r.productosTopCompras.isEmpty)
                const _SinDatos('Sin compras en este período.')
              else
                ...r.productosTopCompras.map(
                  (p) => _FilaProducto(
                    nombre: p.nombre,
                    detalle: '${_entero.format(p.cantidad)} uds.',
                    monto: _moneda.format(p.monto),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GastosTab extends StatefulWidget {
  final ApiClient api;
  const _GastosTab({required this.api});

  @override
  State<_GastosTab> createState() => _GastosTabState();
}

class _GastosTabState extends State<_GastosTab> {
  ReporteGastos? _reporte;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await widget.api.obtenerReporte('gastos');
      if (!mounted) return;
      setState(() {
        _reporte = ReporteGastos.fromJson(data);
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje == 'sesion_expirada'
            ? 'Tu sesión expiró — vuelve a entrar.'
            : e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar el reporte — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EstadoCarga(
      cargando: _cargando,
      error: _error,
      onReintentar: _cargar,
      contentBuilder: () {
        final r = _reporte!;
        return RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ResumenGrid(
                filas: [
                  _Stat('Gastos', '${r.totalGastosCount}'),
                  _Stat('Total', _moneda.format(r.totalGastado)),
                  _Stat('Promedio', _moneda.format(r.promedioGasto)),
                  _Stat('Categoría principal', r.categoriaPrincipal),
                ],
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Por categoría'),
              if (r.categoriasTop.isEmpty)
                const _SinDatos('Sin gastos en este período.')
              else
                ...r.categoriasTop.map(
                  (c) => _FilaProducto(
                    nombre: c.categoria,
                    detalle: '${c.cantidad} registro(s)',
                    monto: _moneda.format(c.monto),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Carga/error/contenido compartido por las 3 pestañas.
class _EstadoCarga extends StatelessWidget {
  final bool cargando;
  final String? error;
  final VoidCallback onReintentar;
  // Perezoso a propósito: mientras cargando == true o error != null, el
  // reporte todavía puede ser null — si esto fuera un Widget ya construido
  // (en vez de una función), Dart lo evaluaría de inmediato y tronaría con
  // "Null check operator used on a null value" antes de llegar al if de abajo.
  final Widget Function() contentBuilder;

  const _EstadoCarga({
    required this.cargando,
    required this.error,
    required this.onReintentar,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onReintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    return contentBuilder();
  }
}

class _Stat {
  final String etiqueta;
  final String valor;
  _Stat(this.etiqueta, this.valor);
}

class _ResumenGrid extends StatelessWidget {
  final List<_Stat> filas;
  const _ResumenGrid({required this.filas});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: filas
          .map(
            (f) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    f.etiqueta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.valor,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;
  const _TituloSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }
}

class _SinDatos extends StatelessWidget {
  final String texto;
  const _SinDatos(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(texto, style: const TextStyle(color: AppColors.textMuted));
  }
}

class _FilaProducto extends StatelessWidget {
  final String nombre;
  final String detalle;
  final String monto;

  const _FilaProducto({
    required this.nombre,
    required this.detalle,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            monto,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
