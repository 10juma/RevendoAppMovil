double? _numN(dynamic v) => v == null ? null : (v as num).toDouble();

class RecetaItem {
  final String insumoId;
  final String insumoNombre;
  final double cantidad;

  RecetaItem({
    required this.insumoId,
    required this.insumoNombre,
    required this.cantidad,
  });

  factory RecetaItem.fromJson(Map<String, dynamic> json) => RecetaItem(
    insumoId: json['insumoId'] as String,
    insumoNombre: json['insumoNombre'] as String,
    cantidad: (json['cantidad'] as num).toDouble(),
  );
}

/// Espejo de Revendo.Api/Dtos/ProductoDto.cs.
class Producto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final String unidadMedida;
  final double? precioVenta;
  final double? costo;
  final String? marca;
  final String? categoria;
  final String? sku;
  final double? stockMinimo;
  final bool manejaCaducidad;
  final bool activo;
  final List<RecetaItem> receta;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.unidadMedida,
    required this.precioVenta,
    required this.costo,
    required this.marca,
    required this.categoria,
    required this.sku,
    required this.stockMinimo,
    required this.manejaCaducidad,
    required this.activo,
    required this.receta,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    tipo: json['tipo'] as String,
    unidadMedida: json['unidadMedida'] as String,
    precioVenta: _numN(json['precioVenta']),
    costo: _numN(json['costo']),
    marca: json['marca'] as String?,
    categoria: json['categoria'] as String?,
    sku: json['sku'] as String?,
    stockMinimo: _numN(json['stockMinimo']),
    manejaCaducidad: json['manejaCaducidad'] as bool,
    activo: json['activo'] as bool,
    receta: (json['receta'] as List)
        .map((e) => RecetaItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
