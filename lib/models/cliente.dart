/// Espejo de Revendo.Api/Dtos/ClienteDto.cs.
class Cliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.notas,
    required this.activo,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    telefono: json['telefono'] as String?,
    email: json['email'] as String?,
    direccion: json['direccion'] as String?,
    notas: json['notas'] as String?,
    activo: json['activo'] as bool,
  );
}
