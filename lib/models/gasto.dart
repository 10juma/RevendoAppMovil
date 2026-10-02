/// Espejo de Revendo.Api/Dtos/GastoDto.cs — categoria ya viene como etiqueta
/// en español (GastosController.CategoriaLabel del lado del servidor).
class Gasto {
  final String id;
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final double monto;
  final String? nota;

  Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.nota,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
    id: json['id'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    categoria: json['categoria'] as String,
    descripcion: json['descripcion'] as String,
    monto: (json['monto'] as num).toDouble(),
    nota: json['nota'] as String?,
  );
}
