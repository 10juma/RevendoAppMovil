/// Espejo de DashboardDto (Revendo.Api/Dtos/DashboardDto.cs) — resumen de
/// solo lectura del mes en curso, lo que regresa GET /api/dashboard.
class Dashboard {
  final String tenantNombre;
  final String mes;
  final int ventasMes;
  final double ingresosMes;
  final double ticketPromedioMes;
  final String productoTopMes;
  final int clientesNuevosMes;
  final double comprasMes;
  final int comprasCountMes;
  final double gastosMes;
  final int gastosCountMes;
  final double ingresoNetoMes;
  final double pendienteCobrar;
  final int ventasPendientesCobro;

  Dashboard({
    required this.tenantNombre,
    required this.mes,
    required this.ventasMes,
    required this.ingresosMes,
    required this.ticketPromedioMes,
    required this.productoTopMes,
    required this.clientesNuevosMes,
    required this.comprasMes,
    required this.comprasCountMes,
    required this.gastosMes,
    required this.gastosCountMes,
    required this.ingresoNetoMes,
    required this.pendienteCobrar,
    required this.ventasPendientesCobro,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    double num_(dynamic v) => (v as num).toDouble();
    return Dashboard(
      tenantNombre: json['tenantNombre'] as String,
      mes: json['mes'] as String,
      ventasMes: json['ventasMes'] as int,
      ingresosMes: num_(json['ingresosMes']),
      ticketPromedioMes: num_(json['ticketPromedioMes']),
      productoTopMes: json['productoTopMes'] as String,
      clientesNuevosMes: json['clientesNuevosMes'] as int,
      comprasMes: num_(json['comprasMes']),
      comprasCountMes: json['comprasCountMes'] as int,
      gastosMes: num_(json['gastosMes']),
      gastosCountMes: json['gastosCountMes'] as int,
      ingresoNetoMes: num_(json['ingresoNetoMes']),
      pendienteCobrar: num_(json['pendienteCobrar']),
      ventasPendientesCobro: json['ventasPendientesCobro'] as int,
    );
  }
}
