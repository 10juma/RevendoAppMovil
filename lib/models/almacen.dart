/// Espejo de Revendo.Api/Dtos/AlmacenDto.cs.
class Almacen {
  final String id;
  final String nombre;
  final String tipo;
  final String? direccion;
  final String? telefono;
  final bool esPrincipal;
  final bool activo;

  Almacen({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.direccion,
    required this.telefono,
    required this.esPrincipal,
    required this.activo,
  });

  factory Almacen.fromJson(Map<String, dynamic> json) => Almacen(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    tipo: json['tipo'] as String,
    direccion: json['direccion'] as String?,
    telefono: json['telefono'] as String?,
    esPrincipal: json['esPrincipal'] as bool,
    activo: json['activo'] as bool,
  );
}
