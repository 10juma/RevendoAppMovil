import 'package:flutter/material.dart';

import '../iconos_menu.dart';
import '../models/sesion.dart';
import '../services/api_client.dart';
import '../theme.dart';

/// Pantalla genérica de solo lectura: AppBar + lista con pull-to-refresh +
/// manejo de carga/error/vacío. Cada módulo nuevo (Productos, Almacenes,
/// Compras, etc.) solo aporta cómo pedir los datos y cómo dibujar cada
/// renglón — todo lo demás (loading, error, "sin registros", refresh) es
/// el mismo código una sola vez.
class SimpleListScreen<T> extends StatefulWidget {
  final String titulo;
  final Sesion sesion;
  final Future<List<T>> Function(ApiClient api) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String vacioTexto;
  // Se reevalúan en cada build — el filtro vive en el State del propio
  // screen de cada módulo (ver FilterBar), este widget solo aplica el
  // predicado sobre la lista ya cargada, sin volver a pedirla a la API.
  final bool Function(T item)? filtro;
  final Widget? filtroBar;
  final String vacioFiltradoTexto;
  // Avisa a la pantalla dueña cada vez que (re)carga, para que pueda armar
  // las opciones de sus dropdowns de filtro (p. ej. almacenes distintos)
  // a partir de los datos ya traídos, sin pedirlos otra vez.
  final void Function(List<T> items)? onCargado;
  final Widget? floatingActionButton;
  final IconData? icono;

  const SimpleListScreen({
    super.key,
    required this.titulo,
    required this.sesion,
    required this.fetch,
    required this.itemBuilder,
    this.vacioTexto = 'Sin registros.',
    this.filtro,
    this.filtroBar,
    this.vacioFiltradoTexto = 'Nada coincide con esos filtros.',
    this.onCargado,
    this.floatingActionButton,
    this.icono,
  });

  @override
  State<SimpleListScreen<T>> createState() => SimpleListScreenState<T>();
}

/// Pública (no privada) para que cada pantalla dueña pueda forzar una
/// recarga desde afuera con un GlobalKey después de crear/editar/borrar algo
/// en un formulario que se abrió por encima de esta lista.
class SimpleListScreenState<T> extends State<SimpleListScreen<T>> {
  List<T>? _items;
  bool _cargando = true;
  String? _error;

  ApiClient get _api => ApiClient(token: widget.sesion.token);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> reload() => _cargar();

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await widget.fetch(_api);
      if (!mounted) return;
      setState(() {
        _items = data;
        _cargando = false;
      });
      widget.onCargado?.call(data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje == 'sesion_expirada'
            ? 'Tu sesión expiró — vuelve a entrar.'
            : e.mensaje;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar — revisa tu internet.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.icono == null
            ? Text(widget.titulo)
            : TituloConIcono(icono: widget.icono!, texto: widget.titulo),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Column(
        children: [
          if (widget.filtroBar != null) widget.filtroBar!,
          Expanded(
            child: RefreshIndicator(onRefresh: _cargar, child: _buildBody()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      );
    }

    final todos = _items!;
    final mostrados = widget.filtro == null
        ? todos
        : todos.where(widget.filtro!).toList();

    if (mostrados.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                todos.isEmpty ? widget.vacioTexto : widget.vacioFiltradoTexto,
                style: const TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: mostrados.length,
      itemBuilder: (ctx, i) => widget.itemBuilder(ctx, mostrados[i]),
    );
  }
}
