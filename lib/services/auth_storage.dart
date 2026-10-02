import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Guarda la sesión completa (token + datos del usuario) en disco para no
/// pedir login cada vez que se abre la app.
class AuthStorage {
  static const _clave = 'revendo_sesion';

  static Future<void> guardar(Map<String, dynamic> sesionJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(sesionJson));
  }

  static Future<Map<String, dynamic>?> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_clave);
    if (crudo == null) return null;
    return jsonDecode(crudo) as Map<String, dynamic>;
  }

  static Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
