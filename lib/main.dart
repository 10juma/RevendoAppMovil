import 'package:flutter/material.dart';

import 'models/sesion.dart';
import 'screens/dashboard_screen.dart';
import 'screens/entregas_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_storage.dart';
import 'theme.dart';

void main() {
  runApp(const RevendoApp());
}

class RevendoApp extends StatelessWidget {
  const RevendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revendo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _Arranque(),
    );
  }
}

/// Revisa si ya hay una sesión guardada (de un login anterior) antes de
/// decidir si mostrar Login o Mis entregas — así el repartidor no tiene que
/// volver a entrar cada vez que abre la app.
class _Arranque extends StatefulWidget {
  const _Arranque();

  @override
  State<_Arranque> createState() => _ArranqueState();
}

class _ArranqueState extends State<_Arranque> {
  Sesion? _sesion;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final json = await AuthStorage.cargar();
    if (!mounted) return;
    setState(() {
      _sesion = json != null ? Sesion.fromJson(json) : null;
      _cargando = false;
    });
  }

  void _onLogin(Sesion sesion) => setState(() => _sesion = sesion);

  void _onLogout() => setState(() => _sesion = null);

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_sesion == null) {
      return LoginScreen(onLogin: _onLogin);
    }
    // Repartidor solo ve sus entregas; Admin/Vendedor ven el resumen del negocio.
    if (_sesion!.rol == 'Repartidor') {
      return EntregasScreen(sesion: _sesion!, onLogout: _onLogout);
    }
    return DashboardScreen(sesion: _sesion!, onLogout: _onLogout);
  }
}
