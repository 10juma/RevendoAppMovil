/// Espejo de Revendo.Api/Dtos/MovimientoDto.cs — Tipo: "Ajuste" | "Produccion" | "Compra" | "Venta".
class Movimiento {
  final DateTime fecha;
  final String productoNombre;
  final String almacenNombre;
  final String tipo;
  final double cantidad;
  final String? nota;

  Movimiento({
    required this.fecha,
    required this.productoNombre,
    required this.almacenNombre,
    required this.tipo,
    required this.cantidad,
    required this.nota,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) => Movimiento(
    fecha: DateTime.parse(json['fecha'] as String),
    productoNombre: json['productoNombre'] as String,
    almacenNombre: json['almacenNombre'] as String,
    tipo: json['tipo'] as String,
    cantidad: (json['cantidad'] as num).toDouble(),
    nota: json['nota'] as String?,
  );
}
