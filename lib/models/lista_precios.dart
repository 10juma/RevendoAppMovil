double? _numN(dynamic v) => v == null ? null : (v as num).toDouble();

class ListaPreciosItem {
  final String productoId;
  final String producto;
  final String? nombreMostrado;
  final double? precioLista;
  final double? descuentoPorcentaje;

  ListaPreciosItem({
    required this.productoId,
    required this.producto,
    required this.nombreMostrado,
    required this.precioLista,
    required this.descuentoPorcentaje,
  });

  factory ListaPreciosItem.fromJson(Map<String, dynamic> json) =>
      ListaPreciosItem(
        productoId: json['productoId'] as String,
        producto: json['producto'] as String,
        nombreMostrado: json['nombreMostrado'] as String?,
        precioLista: _numN(json['precioLista']),
        descuentoPorcentaje: _numN(json['descuentoPorcentaje']),
      );
}

/// Espejo de Revendo.Api/Dtos/ListaPreciosDto.cs.
class ListaPrecios {
  final String id;
  final String nombre;
  final bool activa;
  final DateTime creadoEn;
  final List<ListaPreciosItem> items;

  ListaPrecios({
    required this.id,
    required this.nombre,
    required this.activa,
    required this.creadoEn,
    required this.items,
  });

  factory ListaPrecios.fromJson(Map<String, dynamic> json) => ListaPrecios(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    activa: json['activa'] as bool,
    creadoEn: DateTime.parse(json['creadoEn'] as String),
    items: (json['items'] as List)
        .map((e) => ListaPreciosItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
