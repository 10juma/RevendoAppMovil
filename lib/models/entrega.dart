/// Espejo de EntregaDto/EntregaItemDto (Revendo.Api/Dtos/EntregaDto.cs) —
/// lo que regresa GET /api/entregas. Sin precios/totales a propósito, igual
/// que /Repartidor en el panel web.
class EntregaItem {
  final String producto;
  final double cantidad;

  EntregaItem({required this.producto, required this.cantidad});

  factory EntregaItem.fromJson(Map<String, dynamic> json) {
    return EntregaItem(
      producto: json['producto'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
    );
  }
}

class Entrega {
  final String id;
  final DateTime fecha;
  final String? clienteNombre;
  final String? clienteTelefono;
  final String? clienteDireccion;
  final String almacenNombre;
  final String estadoEntrega; // "Pendiente" | "EnRuta" | "Entregado"
  final List<EntregaItem> items;

  Entrega({
    required this.id,
    required this.fecha,
    this.clienteNombre,
    this.clienteTelefono,
    this.clienteDireccion,
    required this.almacenNombre,
    required this.estadoEntrega,
    required this.items,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      clienteNombre: json['clienteNombre'] as String?,
      clienteTelefono: json['clienteTelefono'] as String?,
      clienteDireccion: json['clienteDireccion'] as String?,
      almacenNombre: json['almacenNombre'] as String,
      estadoEntrega: json['estadoEntrega'] as String,
      items: (json['items'] as List)
          .map((e) => EntregaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get etiquetaEstado => switch (estadoEntrega) {
    'Pendiente' => 'Pendiente',
    'EnRuta' => 'En ruta',
    'Entregado' => 'Entregado',
    _ => estadoEntrega,
  };

  /// Vacío cuando ya está Entregado — no hay siguiente acción.
  String get etiquetaAccion => switch (estadoEntrega) {
    'Pendiente' => 'Marcar en ruta',
    'EnRuta' => 'Marcar entregado',
    _ => '',
  };
}
