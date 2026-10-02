/// Espejo de Revendo.Api/Dtos/ProveedorDto.cs.
class Proveedor {
  final String id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final bool activo;

  Proveedor({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.notas,
    required this.activo,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    contacto: json['contacto'] as String?,
    telefono: json['telefono'] as String?,
    email: json['email'] as String?,
    direccion: json['direccion'] as String?,
    notas: json['notas'] as String?,
    activo: json['activo'] as bool,
  );
}
