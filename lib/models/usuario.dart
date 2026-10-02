/// Espejo de Revendo.Api/Dtos/UsuarioDto.cs — nunca trae password hash.
class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final bool emailConfirmado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    required this.emailConfirmado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    email: json['email'] as String,
    rol: json['rol'] as String,
    activo: json['activo'] as bool,
    emailConfirmado: json['emailConfirmado'] as bool,
  );
}
