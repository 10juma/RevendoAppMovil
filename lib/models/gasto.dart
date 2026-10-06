/// Espejo de Revendo.Api/Dtos/GastoDto.cs — categoria ya viene como etiqueta
/// en español (GastosController.CategoriaLabel del lado del servidor).
class Gasto {
  final String id;
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final double monto;
  final String? nota;

  /// Quién registró el gasto; null en los anteriores a este dato.
  final String? usuarioId;
  final String? usuarioNombre;

  Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.nota,
    this.usuarioId,
    this.usuarioNombre,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
    id: json['id'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    categoria: json['categoria'] as String,
    descripcion: json['descripcion'] as String,
    monto: (json['monto'] as num).toDouble(),
    nota: json['nota'] as String?,
    usuarioId: json['usuarioId'] as String?,
    usuarioNombre: json['usuarioNombre'] as String?,
  );
}
