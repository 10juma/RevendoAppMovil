/// Espejo de Revendo.Api/Dtos/ExistenciaDto.cs.
class Existencia {
  final String productoId;
  final String productoNombre;
  final String productoTipo;
  final double? stockMinimo;
  final String almacenId;
  final String almacenNombre;
  final double cantidad;

  Existencia({
    required this.productoId,
    required this.productoNombre,
    required this.productoTipo,
    required this.stockMinimo,
    required this.almacenId,
    required this.almacenNombre,
    required this.cantidad,
  });

  factory Existencia.fromJson(Map<String, dynamic> json) => Existencia(
    productoId: json['productoId'] as String,
    productoNombre: json['productoNombre'] as String,
    productoTipo: json['productoTipo'] as String,
    stockMinimo: json['stockMinimo'] == null
        ? null
        : (json['stockMinimo'] as num).toDouble(),
    almacenId: json['almacenId'] as String,
    almacenNombre: json['almacenNombre'] as String,
    cantidad: (json['cantidad'] as num).toDouble(),
  );
}
