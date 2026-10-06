class VentaItem {
  final String productoId;
  final String producto;
  final double cantidad;
  final double precioUnitario;

  VentaItem({
    required this.productoId,
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory VentaItem.fromJson(Map<String, dynamic> json) => VentaItem(
    productoId: json['productoId'] as String,
    producto: json['producto'] as String,
    cantidad: (json['cantidad'] as num).toDouble(),
    precioUnitario: (json['precioUnitario'] as num).toDouble(),
  );
}

/// Espejo de Revendo.Api/Dtos/VentaDto.cs — para Admin/Vendedor, sí incluye
/// precios/totales (a diferencia de Entrega, que es lo que ve Repartidor).
class Venta {
  final String id;
  final DateTime fecha;
  final String? clienteId;
  final String? clienteNombre;
  final String almacenId;
  final String almacenNombre;
  final String canal;
  final String? nota;
  final bool pagada;
  final String estadoEntrega;
  final String? repartidorNombre;
  final double total;
  final List<VentaItem> items;

  /// Quién registró la venta; null en las ventas anteriores a este dato.
  final String? usuarioNombre;
  final String? usuarioId;

  /// Dirección del cliente (si la tiene) — para que en Rutas se vea a dónde va la entrega.
  final String? clienteDireccion;

  Venta({
    required this.id,
    required this.fecha,
    required this.clienteId,
    required this.clienteNombre,
    required this.almacenId,
    required this.almacenNombre,
    required this.canal,
    required this.nota,
    required this.pagada,
    required this.estadoEntrega,
    required this.repartidorNombre,
    required this.total,
    required this.items,
    this.usuarioNombre,
    this.usuarioId,
    this.clienteDireccion,
  });

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
    id: json['id'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    clienteId: json['clienteId'] as String?,
    clienteNombre: json['clienteNombre'] as String?,
    almacenId: json['almacenId'] as String,
    almacenNombre: json['almacenNombre'] as String,
    canal: json['canal'] as String,
    nota: json['nota'] as String?,
    pagada: json['pagada'] as bool,
    estadoEntrega: json['estadoEntrega'] as String,
    repartidorNombre: json['repartidorNombre'] as String?,
    total: (json['total'] as num).toDouble(),
    items: (json['items'] as List)
        .map((e) => VentaItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    usuarioNombre: json['usuarioNombre'] as String?,
    usuarioId: json['usuarioId'] as String?,
    clienteDireccion: json['clienteDireccion'] as String?,
  );
}
