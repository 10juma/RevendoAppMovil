/// Espejo de TokenDto (Revendo.Application/DTOs/TokenDto.cs) — lo que regresa
/// POST /api/auth/login. ASP.NET Core serializa en camelCase por default.
class Sesion {
  final String token;
  final String usuarioId;
  final String nombre;
  final String email;
  final String rol;
  final String tenantId;
  final String tenantNombre;
  final DateTime expira;

  Sesion({
    required this.token,
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.tenantId,
    required this.tenantNombre,
    required this.expira,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      token: json['token'] as String,
      usuarioId: json['usuarioId'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      tenantId: json['tenantId'] as String,
      tenantNombre: json['tenantNombre'] as String,
      expira: DateTime.parse(json['expira'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'usuarioId': usuarioId,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    'tenantId': tenantId,
    'tenantNombre': tenantNombre,
    'expira': expira.toIso8601String(),
  };
}
