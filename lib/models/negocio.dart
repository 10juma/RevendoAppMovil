/// Espejo de Revendo.Api/Dtos/NegocioDto.cs.
class Negocio {
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final String? telefono;
  final String? emailContacto;
  final String? facebook;
  final String? instagram;
  final String? whatsApp;
  final String suscripcionEstado;

  Negocio({
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.telefono,
    required this.emailContacto,
    required this.facebook,
    required this.instagram,
    required this.whatsApp,
    required this.suscripcionEstado,
  });

  factory Negocio.fromJson(Map<String, dynamic> json) => Negocio(
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    direccion: json['direccion'] as String?,
    telefono: json['telefono'] as String?,
    emailContacto: json['emailContacto'] as String?,
    facebook: json['facebook'] as String?,
    instagram: json['instagram'] as String?,
    whatsApp: json['whatsApp'] as String?,
    suscripcionEstado: json['suscripcionEstado'] as String,
  );
}
