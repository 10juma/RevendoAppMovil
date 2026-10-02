class CompraItem {
  final String productoId;
  final String producto;
  final double cantidad;
  final double costoUnitario;

  CompraItem({
    required this.productoId,
    required this.producto,
    required this.cantidad,
    required this.costoUnitario,
  });

  factory CompraItem.fromJson(Map<String, dynamic> json) => CompraItem(
    productoId: json['productoId'] as String,
    producto: json['producto'] as String,
    cantidad: (json['cantidad'] as num).toDouble(),
    costoUnitario: (json['costoUnitario'] as num).toDouble(),
  );
}

/// Espejo de Revendo.Api/Dtos/CompraDto.cs.
class Compra {
  final String id;
  final DateTime fecha;
  final String proveedorId;
  final String proveedorNombre;
  final String almacenId;
  final String almacenNombre;
  final String? nota;
  final double total;
  final List<CompraItem> items;

  Compra({
    required this.id,
    required this.fecha,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.almacenId,
    required this.almacenNombre,
    required this.nota,
    required this.total,
    required this.items,
  });

  factory Compra.fromJson(Map<String, dynamic> json) => Compra(
    id: json['id'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    proveedorId: json['proveedorId'] as String,
    proveedorNombre: json['proveedorNombre'] as String,
    almacenId: json['almacenId'] as String,
    almacenNombre: json['almacenNombre'] as String,
    nota: json['nota'] as String?,
    total: (json['total'] as num).toDouble(),
    items: (json['items'] as List)
        .map((e) => CompraItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
