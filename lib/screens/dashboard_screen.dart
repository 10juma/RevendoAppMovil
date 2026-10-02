import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../iconos_menu.dart';
import '../models/dashboard.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../theme.dart';
import 'almacenes_screen.dart';
import 'cliente_form_screen.dart';
import 'clientes_screen.dart';
import 'compras_screen.dart';
import 'equipo_screen.dart';
import 'existencias_screen.dart';
import 'gastos_screen.dart';
import 'listas_precios_screen.dart';
import 'negocio_screen.dart';
import 'produccion_screen.dart';
import 'productos_screen.dart';
import 'proveedores_screen.dart';
import 'reportes_screen.dart';
import 'rutas_screen.dart';
import 'venta_form_screen.dart';
import 'ventas_screen.dart';

const _nombresMes = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Mes puntual, o año completo si [mes] == 0 — mismo sentinel que usa
/// Admin/Index.cshtml.cs en la web.
class _MesOpcion {
  final int anio;
  final int mes;
  final String etiqueta;
  const _MesOpcion(this.anio, this.mes, this.etiqueta);
}

/// Resumen de solo lectura para Admin/Vendedor — mismos números y el mismo
/// selector de período (mes en curso + 3 anteriores, o año completo) que la
/// parte de arriba de /Admin/Index en el panel web. Repartidor nunca llega
/// aquí, se queda en EntregasScreen.
class DashboardScreen extends StatefulWidget {
  final Sesion sesion;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.sesion,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Dashboard? _dashboard;
  bool _cargando = true;
  String? _error;

  late final List<_MesOpcion> _opciones;
  late _MesOpcion _periodo;

  final _moneda = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _opciones = _construirOpciones();
    _periodo = _opciones.first;
    _cargar();
  }

  /// Mes en curso + los 3 anteriores, más "Todo (año)" — mismo criterio que
  /// Admin/Index.cshtml.cs en la web.
  List<_MesOpcion> _construirOpciones() {
    final hoy = DateTime.now();
    final meses = List.generate(4, (i) {
      final d = DateTime(hoy.year, hoy.month - i, 1);
      return _MesOpcion(d.year, d.month, '${_nombresMes[d.month - 1]} ${d.year}');
    });
    return [...meses, _MesOpcion(hoy.year, 0, 'Todo ${hoy.year}')];
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await _api.obtenerDashboard(
        anio: _periodo.anio,
        mes: _periodo.mes,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = Dashboard.fromJson(data);
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (e.mensaje == 'sesion_expirada') {
        await _cerrarSesion();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar el resumen — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  Future<void> _cerrarSesion() async {
    await AuthStorage.borrar();
    if (mounted) widget.onLogout();
  }

  // Solo para Vendedor — Admin cierra sesión desde Mi negocio (no puede
  // llegar ahí porque esa sección es Admin-only en el menú).
  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cerrarSesion();
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirNuevaVenta() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VentaFormScreen(sesion: widget.sesion)),
    );
    if (guardado == true) _cargar();
  }

  Future<void> _abrirNuevoCliente() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClienteFormScreen(sesion: widget.sesion)),
    );
    // Afecta "Clientes nuevos" en la tarjeta de Ventas del Dashboard.
    if (guardado == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TituloConIcono(icono: IconosMenu.dashboard, texto: 'Dashboard'),
      ),
      drawer: _buildDrawer(context),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab-nuevo-cliente',
            onPressed: _abrirNuevoCliente,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Nuevo cliente'),
            backgroundColor: AppColors.cardBg,
            foregroundColor: AppColors.accentDark,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab-nueva-venta',
            onPressed: _abrirNuevaVenta,
            icon: const Icon(Icons.point_of_sale_rounded),
            label: const Text('Nueva venta'),
            backgroundColor: AppColors.accentDark,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          _selectorPeriodo(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    )
                  : _buildContenido(_dashboard!),
            ),
          ),
        ],
      ),
    );
  }

  void _elegirPeriodo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _opciones.map((o) {
            final seleccionado = o.anio == _periodo.anio && o.mes == _periodo.mes;
            return ListTile(
              title: Text(
                o.etiqueta,
                style: TextStyle(
                  fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                  color: seleccionado ? AppColors.accentDark : AppColors.text,
                ),
              ),
              trailing: seleccionado
                  ? const Icon(Icons.check_rounded, color: AppColors.accentDark)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                if (seleccionado) return;
                setState(() => _periodo = o);
                _cargar();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _selectorPeriodo() {
    return InkWell(
      onTap: _elegirPeriodo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _periodo.etiqueta,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(Dashboard d) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          d.tenantNombre,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _tarjetaFinanzas(
          titulo: 'Ventas',
          monto: d.ingresosMes,
          colorPunto: AppColors.accent,
          filas: [
            _Fila('Ventas registradas', '${d.ventasMes}'),
            _Fila('Ticket promedio', _moneda.format(d.ticketPromedioMes)),
            _Fila('Producto más vendido', d.productoTopMes),
            _Fila('Clientes nuevos', '${d.clientesNuevosMes}'),
          ],
        ),
        const SizedBox(height: 14),
        _tarjetaFinanzas(
          titulo: 'Compras',
          monto: d.comprasMes,
          colorPunto: const Color(0xFF2563EB),
          filas: [_Fila('Compras registradas', '${d.comprasCountMes}')],
        ),
        const SizedBox(height: 14),
        _tarjetaFinanzas(
          titulo: 'Gastos',
          monto: d.gastosMes,
          colorPunto: const Color(0xFFDC2626),
          filas: [_Fila('Gastos registrados', '${d.gastosCountMes}')],
        ),
        const SizedBox(height: 18),
        _bannerGrande(
          etiqueta: 'Ingreso neto del período',
          formula: 'Ventas − Compras − Gastos',
          valor: d.ingresoNetoMes,
          positivo: d.ingresoNetoMes >= 0,
        ),
        if (d.ventasPendientesCobro > 0) ...[
          const SizedBox(height: 14),
          _bannerGrande(
            etiqueta: 'Pendiente por cobrar',
            formula:
                '${d.ventasPendientesCobro} venta(s) marcadas como no pagadas',
            valor: d.pendienteCobrar,
            positivo: null, // ámbar, ni verde ni rojo
          ),
        ],
      ],
    );
  }

  Widget _tarjetaFinanzas({
    required String titulo,
    required double monto,
    required Color colorPunto,
    required List<_Fila> filas,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colorPunto,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _moneda.format(monto),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          ...filas.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    f.etiqueta,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      f.valor,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// positivo == true → verde, false → rojo, null → ámbar (pendiente por cobrar).
  Widget _bannerGrande({
    required String etiqueta,
    required String formula,
    required double valor,
    required bool? positivo,
  }) {
    final Color fondo = positivo == null
        ? const Color(0xFFFEF3C7)
        : positivo
        ? AppColors.successBg
        : AppColors.errorBg;
    final Color textoValor = positivo == null
        ? const Color(0xFF92400E)
        : positivo
        ? AppColors.successText
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formula,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            _moneda.format(valor),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textoValor,
            ),
          ),
        ],
      ),
    );
  }

  /// Mismo menú y mismo criterio de roles que _NavAdmin.cshtml en la web:
  /// Admin ve todo; Vendedor solo el grupo de Ventas (Clientes/Ventas, sin
  /// Listas de precios, que es Admin-only).
  Widget _buildDrawer(BuildContext context) {
    final esAdmin = widget.sesion.rol == 'Admin';

    void ir(Widget pantalla) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    }

    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                widget.sesion.tenantNombre,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
            ),
            _navItem(
              icon: IconosMenu.dashboard,
              texto: 'Dashboard',
              onTap: () => Navigator.pop(context),
            ),
            if (esAdmin)
              _navItem(
                icon: IconosMenu.reportes,
                texto: 'Reportes',
                onTap: () => ir(ReportesScreen(sesion: widget.sesion)),
              ),
            if (esAdmin) ...[
              _navGroup('Inventario'),
              _navItem(
                icon: IconosMenu.productos,
                texto: 'Productos',
                onTap: () => ir(ProductosScreen(sesion: widget.sesion)),
              ),
              _navItem(
                icon: IconosMenu.almacenes,
                texto: 'Almacenes',
                onTap: () => ir(AlmacenesScreen(sesion: widget.sesion)),
              ),
              _navItem(
                icon: IconosMenu.existencias,
                texto: 'Existencias',
                onTap: () => ir(ExistenciasScreen(sesion: widget.sesion)),
              ),
              _navItem(
                icon: IconosMenu.produccion,
                texto: 'Producción',
                onTap: () => ir(ProduccionScreen(sesion: widget.sesion)),
              ),
              _navGroup('Compras'),
              _navItem(
                icon: IconosMenu.proveedores,
                texto: 'Proveedores',
                onTap: () => ir(ProveedoresScreen(sesion: widget.sesion)),
              ),
              _navItem(
                icon: IconosMenu.compras,
                texto: 'Compras',
                onTap: () => ir(ComprasScreen(sesion: widget.sesion)),
              ),
              _navItem(
                icon: IconosMenu.gastos,
                texto: 'Gastos',
                onTap: () => ir(GastosScreen(sesion: widget.sesion)),
              ),
            ],
            _navGroup('Ventas'),
            _navItem(
              icon: IconosMenu.clientes,
              texto: 'Clientes',
              onTap: () => ir(ClientesScreen(sesion: widget.sesion)),
            ),
            _navItem(
              icon: IconosMenu.ventas,
              texto: 'Ventas',
              onTap: () => ir(VentasScreen(sesion: widget.sesion)),
            ),
            if (esAdmin)
              _navItem(
                icon: IconosMenu.listasPrecios,
                texto: 'Listas de precios',
                onTap: () => ir(ListasPreciosScreen(sesion: widget.sesion)),
              ),
            if (esAdmin) ...[
              _navItem(
                icon: IconosMenu.rutas,
                texto: 'Rutas de reparto',
                onTap: () => ir(RutasScreen(sesion: widget.sesion)),
              ),
              _navGroup('Cuenta'),
              _navItem(
                icon: IconosMenu.equipo,
                texto: 'Equipo',
                onTap: () => ir(EquipoScreen(sesion: widget.sesion)),
              ),
              _navItem(
                icon: IconosMenu.negocio,
                texto: 'Mi negocio',
                onTap: () => ir(NegocioScreen(sesion: widget.sesion, onLogout: widget.onLogout)),
              ),
            ],
            if (!esAdmin) ...[
              _navGroup('Cuenta'),
              _navItem(
                icon: Icons.logout_rounded,
                texto: 'Cerrar sesión',
                onTap: () {
                  Navigator.pop(context);
                  _confirmarLogout();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navGroup(String texto) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
    child: Text(
      texto.toUpperCase(),
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.accentDark,
      ),
    ),
  );

  Widget _navItem({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon, color: AppColors.textMuted, size: 22),
    title: Text(texto, style: const TextStyle(color: AppColors.text)),
    dense: true,
    onTap: onTap,
  );
}

class _Fila {
  final String etiqueta;
  final String valor;
  _Fila(this.etiqueta, this.valor);
}
