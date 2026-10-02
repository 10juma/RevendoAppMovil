import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error ya traducido a un mensaje que se le puede mostrar al repartidor tal
/// cual. El valor especial "sesion_expirada" le dice a la pantalla que debe
/// mandar al usuario de vuelta a Login en lugar de mostrar un mensaje.
class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);
}

/// Espejo delgado de Revendo.Api — mismos endpoints que ya expone el backend
/// (Revendo.Api/Controllers/AuthController.cs y EntregasController.cs).
class ApiClient {
  static const String baseUrl = 'https://revendoapi.globalappsuite.com.mx';

  final String? token;
  const ApiClient({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) {
      throw ApiException('Correo o contraseña incorrectos.');
    }
    if (res.statusCode != 200) {
      throw ApiException('No se pudo iniciar sesión — intenta de nuevo.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listarEntregas() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/entregas'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) throw ApiException('sesion_expirada');
    if (res.statusCode != 200) {
      throw ApiException('No se pudieron cargar tus entregas.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  /// Regresa el nuevo estado ("Pendiente" | "EnRuta" | "Entregado").
  Future<String> avanzarEntrega(String id) async {
    final res = await http
        .post(Uri.parse('$baseUrl/api/entregas/$id/avanzar'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) throw ApiException('sesion_expirada');
    if (res.statusCode == 404) {
      throw ApiException('Esta entrega ya no está disponible.');
    }
    if (res.statusCode != 200) {
      throw ApiException('No se pudo actualizar la entrega.');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return data['estadoEntrega'] as String;
  }

  /// Solo Admin/Vendedor — Repartidor recibe 403 si lo llama (DashboardController.cs).
  /// Sin año/mes, el backend usa el mes en curso; mes == 0 es "todo el año".
  Future<Map<String, dynamic>> obtenerDashboard({int? anio, int? mes}) async {
    final uri = Uri.parse('$baseUrl/api/dashboard').replace(
      queryParameters: {
        if (anio != null) 'anio': '$anio',
        if (mes != null) 'mes': '$mes',
      },
    );
    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) throw ApiException('sesion_expirada');
    if (res.statusCode != 200) {
      throw ApiException('No se pudo cargar el resumen del negocio.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Solo Admin — las 3 pestañas de /Admin/Reportes (ReportesController.cs).
  /// Sin fechas, el backend usa los últimos 30 días.
  Future<Map<String, dynamic>> obtenerReporte(String pestana) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/reportes/$pestana'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) throw ApiException('sesion_expirada');
    if (res.statusCode != 200) {
      throw ApiException('No se pudo cargar el reporte.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<dynamic> _get(String path) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 401) throw ApiException('sesion_expirada');
    if (res.statusCode != 200) {
      throw ApiException('No se pudo cargar la información.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // Los módulos de abajo son todos de solo lectura por ahora (mismo criterio
  // que Entregas/Dashboard/Reportes) — mismos endpoints que ya expone la web.
  Future<List<dynamic>> listarProductos() async =>
      await _get('/api/productos') as List<dynamic>;

  Future<List<dynamic>> listarAlmacenes() async =>
      await _get('/api/almacenes') as List<dynamic>;

  Future<List<dynamic>> listarExistencias() async =>
      await _get('/api/existencias') as List<dynamic>;

  Future<List<dynamic>> listarMovimientos() async =>
      await _get('/api/movimientos') as List<dynamic>;

  Future<List<dynamic>> listarProveedores() async =>
      await _get('/api/proveedores') as List<dynamic>;

  Future<List<dynamic>> listarCompras() async =>
      await _get('/api/compras') as List<dynamic>;

  Future<List<dynamic>> listarClientes() async =>
      await _get('/api/clientes') as List<dynamic>;

  Future<List<dynamic>> listarVentas() async =>
      await _get('/api/ventas') as List<dynamic>;

  Future<List<dynamic>> listarGastos() async =>
      await _get('/api/gastos') as List<dynamic>;

  Future<List<dynamic>> listarListasPrecios() async =>
      await _get('/api/listasprecios') as List<dynamic>;

  Future<List<dynamic>> listarEquipo() async =>
      await _get('/api/equipo') as List<dynamic>;

  Future<Map<String, dynamic>> obtenerNegocio() async =>
      await _get('/api/negocio') as Map<String, dynamic>;

  /// POST/PUT/DELETE genérico — si el servidor regresa 400 con `{ "error": "..." }`
  /// (validación), ese mensaje se le muestra tal cual al usuario en el formulario.
  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final encoded = body == null ? null : jsonEncode(body);
    final res = switch (method) {
      'POST' => await http.post(uri, headers: _headers, body: encoded).timeout(const Duration(seconds: 15)),
      'PUT' => await http.put(uri, headers: _headers, body: encoded).timeout(const Duration(seconds: 15)),
      'DELETE' => await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15)),
      _ => throw ArgumentError('Método no soportado: $method'),
    };

    if (res.statusCode == 401) throw ApiException('sesion_expirada');
    if (res.statusCode == 400) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw ApiException((data['error'] as String?) ?? 'Revisa los datos del formulario.');
    }
    if (res.statusCode == 404) throw ApiException('Ya no existe — alguien más pudo haberlo borrado.');
    if (res.statusCode >= 300) throw ApiException('No se pudo guardar — intenta de nuevo.');
    if (res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // ── Almacenes ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearAlmacen(Map<String, dynamic> body) async =>
      await _send('POST', '/api/almacenes', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarAlmacen(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/almacenes/$id', body) as Map<String, dynamic>;

  // ── Proveedores ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearProveedor(Map<String, dynamic> body) async =>
      await _send('POST', '/api/proveedores', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarProveedor(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/proveedores/$id', body) as Map<String, dynamic>;

  // ── Clientes ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearCliente(Map<String, dynamic> body) async =>
      await _send('POST', '/api/clientes', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarCliente(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/clientes/$id', body) as Map<String, dynamic>;

  // ── Gastos ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearGasto(Map<String, dynamic> body) async =>
      await _send('POST', '/api/gastos', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarGasto(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/gastos/$id', body) as Map<String, dynamic>;
  Future<void> crearGastos(List<Map<String, dynamic>> gastos) async =>
      await _send('POST', '/api/gastos/varios', {'gastos': gastos});
  Future<void> eliminarGasto(String id) async => await _send('DELETE', '/api/gastos/$id');

  // ── Equipo ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearUsuario(Map<String, dynamic> body) async =>
      await _send('POST', '/api/equipo', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarUsuario(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/equipo/$id', body) as Map<String, dynamic>;

  // ── Mi negocio ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> actualizarNegocio(Map<String, dynamic> body) async =>
      await _send('PUT', '/api/negocio', body) as Map<String, dynamic>;

  // ── Listas de precios ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearListaPrecios(Map<String, dynamic> body) async =>
      await _send('POST', '/api/listasprecios', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarListaPrecios(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/listasprecios/$id', body) as Map<String, dynamic>;

  // ── Productos ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearProducto(Map<String, dynamic> body) async =>
      await _send('POST', '/api/productos', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarProducto(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/productos/$id', body) as Map<String, dynamic>;

  // ── Existencias / Producción ─────────────────────────────────────────────
  Future<Map<String, dynamic>> ajustarExistencia(Map<String, dynamic> body) async =>
      await _send('POST', '/api/existencias/ajustar', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> producir(Map<String, dynamic> body) async =>
      await _send('POST', '/api/produccion', body) as Map<String, dynamic>;

  // ── Compras / Ventas ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> crearCompra(Map<String, dynamic> body) async =>
      await _send('POST', '/api/compras', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarCompra(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/compras/$id', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> crearVenta(Map<String, dynamic> body) async =>
      await _send('POST', '/api/ventas', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> actualizarVenta(String id, Map<String, dynamic> body) async =>
      await _send('PUT', '/api/ventas/$id', body) as Map<String, dynamic>;
  Future<Map<String, dynamic>> asignarRepartidor(String ventaId, String? repartidorId) async =>
      await _send('POST', '/api/ventas/$ventaId/asignar-repartidor', {'repartidorId': repartidorId}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> cambiarEstadoEntrega(String ventaId, String estado) async =>
      await _send('POST', '/api/ventas/$ventaId/estado', {'estado': estado}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> vincularCliente(
    String ventaId, {
    String? clienteId,
    String? clienteNuevoNombre,
    String? clienteNuevoTelefono,
  }) async =>
      await _send('POST', '/api/ventas/$ventaId/vincular-cliente', {
        'clienteId': clienteId,
        'clienteNuevoNombre': clienteNuevoNombre,
        'clienteNuevoTelefono': clienteNuevoTelefono,
      }) as Map<String, dynamic>;
}
