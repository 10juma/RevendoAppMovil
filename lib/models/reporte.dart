/// Espejo de los DTOs de Revendo.Api/Dtos/ReporteDto.cs — lo que regresan
/// GET /api/reportes/ventas|compras|gastos (mismos 3 reportes que las
/// pestañas de /Admin/Reportes en el panel web).
double _num(dynamic v) => (v as num).toDouble();

class MontoPorDia {
  final DateTime fecha;
  final double total;

  MontoPorDia({required this.fecha, required this.total});

  factory MontoPorDia.fromJson(Map<String, dynamic> json) => MontoPorDia(
    fecha: DateTime.parse(json['fecha'] as String),
    total: _num(json['total']),
  );
}

class ProductoVentaReporte {
  final String nombre;
  final double cantidad;
  final double ingresos;
  final double margen;

  ProductoVentaReporte({
    required this.nombre,
    required this.cantidad,
    required this.ingresos,
    required this.margen,
  });

  factory ProductoVentaReporte.fromJson(Map<String, dynamic> json) =>
      ProductoVentaReporte(
        nombre: json['nombre'] as String,
        cantidad: _num(json['cantidad']),
        ingresos: _num(json['ingresos']),
        margen: _num(json['margen']),
      );
}

class ReporteVentas {
  final DateTime desde;
  final DateTime hasta;
  final int totalVentas;
  final double totalIngresos;
  final double ticketPromedio;
  final double margenTotal;
  final List<ProductoVentaReporte> productosTop;
  final List<MontoPorDia> serieDiaria;

  ReporteVentas({
    required this.desde,
    required this.hasta,
    required this.totalVentas,
    required this.totalIngresos,
    required this.ticketPromedio,
    required this.margenTotal,
    required this.productosTop,
    required this.serieDiaria,
  });

  factory ReporteVentas.fromJson(Map<String, dynamic> json) => ReporteVentas(
    desde: DateTime.parse(json['desde'] as String),
    hasta: DateTime.parse(json['hasta'] as String),
    totalVentas: json['totalVentas'] as int,
    totalIngresos: _num(json['totalIngresos']),
    ticketPromedio: _num(json['ticketPromedio']),
    margenTotal: _num(json['margenTotal']),
    productosTop: (json['productosTop'] as List)
        .map((e) => ProductoVentaReporte.fromJson(e as Map<String, dynamic>))
        .toList(),
    serieDiaria: (json['serieDiaria'] as List)
        .map((e) => MontoPorDia.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ProductoCompraReporte {
  final String nombre;
  final double cantidad;
  final double monto;

  ProductoCompraReporte({
    required this.nombre,
    required this.cantidad,
    required this.monto,
  });

  factory ProductoCompraReporte.fromJson(Map<String, dynamic> json) =>
      ProductoCompraReporte(
        nombre: json['nombre'] as String,
        cantidad: _num(json['cantidad']),
        monto: _num(json['monto']),
      );
}

class ReporteCompras {
  final DateTime desde;
  final DateTime hasta;
  final int totalCompras;
  final double totalGastadoCompras;
  final double costoPromedioCompra;
  final int proveedoresDistintos;
  final List<ProductoCompraReporte> productosTopCompras;
  final List<MontoPorDia> serieDiaria;

  ReporteCompras({
    required this.desde,
    required this.hasta,
    required this.totalCompras,
    required this.totalGastadoCompras,
    required this.costoPromedioCompra,
    required this.proveedoresDistintos,
    required this.productosTopCompras,
    required this.serieDiaria,
  });

  factory ReporteCompras.fromJson(Map<String, dynamic> json) =>
      ReporteCompras(
        desde: DateTime.parse(json['desde'] as String),
        hasta: DateTime.parse(json['hasta'] as String),
        totalCompras: json['totalCompras'] as int,
        totalGastadoCompras: _num(json['totalGastadoCompras']),
        costoPromedioCompra: _num(json['costoPromedioCompra']),
        proveedoresDistintos: json['proveedoresDistintos'] as int,
        productosTopCompras: (json['productosTopCompras'] as List)
            .map(
              (e) =>
                  ProductoCompraReporte.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        serieDiaria: (json['serieDiaria'] as List)
            .map((e) => MontoPorDia.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CategoriaReporte {
  final String categoria;
  final int cantidad;
  final double monto;

  CategoriaReporte({
    required this.categoria,
    required this.cantidad,
    required this.monto,
  });

  factory CategoriaReporte.fromJson(Map<String, dynamic> json) =>
      CategoriaReporte(
        categoria: json['categoria'] as String,
        cantidad: json['cantidad'] as int,
        monto: _num(json['monto']),
      );
}

class ReporteGastos {
  final DateTime desde;
  final DateTime hasta;
  final int totalGastosCount;
  final double totalGastado;
  final double promedioGasto;
  final String categoriaPrincipal;
  final List<CategoriaReporte> categoriasTop;
  final List<MontoPorDia> serieDiaria;

  ReporteGastos({
    required this.desde,
    required this.hasta,
    required this.totalGastosCount,
    required this.totalGastado,
    required this.promedioGasto,
    required this.categoriaPrincipal,
    required this.categoriasTop,
    required this.serieDiaria,
  });

  factory ReporteGastos.fromJson(Map<String, dynamic> json) => ReporteGastos(
    desde: DateTime.parse(json['desde'] as String),
    hasta: DateTime.parse(json['hasta'] as String),
    totalGastosCount: json['totalGastosCount'] as int,
    totalGastado: _num(json['totalGastado']),
    promedioGasto: _num(json['promedioGasto']),
    categoriaPrincipal: json['categoriaPrincipal'] as String,
    categoriasTop: (json['categoriasTop'] as List)
        .map((e) => CategoriaReporte.fromJson(e as Map<String, dynamic>))
        .toList(),
    serieDiaria: (json['serieDiaria'] as List)
        .map((e) => MontoPorDia.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
