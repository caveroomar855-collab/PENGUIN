import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/articulo.dart';
import '../models/traje.dart';
import '../config/api_config.dart';

class InventarioProvider extends ChangeNotifier {
  List<Articulo> _articulos = [];
  List<Traje> _trajes = [];
  bool _isLoading = false;

  List<Articulo> get articulos => _articulos;
  List<Traje> get trajes => _trajes;
  bool get isLoading => _isLoading;

  List<Articulo> get articulosDisponibles =>
      _articulos.where((a) => a.isDisponible).toList();

  List<Articulo> get articulosAlquilados =>
      _articulos.where((a) => a.isAlquilado).toList();

  List<Articulo> get articulosMantenimiento =>
      _articulos.where((a) => a.isMantenimiento).toList();

  // Resumen por estados (número de artículos con >0 unidades por estado)
  Map<String, int> _estadosResumen = {};
  final Map<String, List<Map<String, dynamic>>> _estadosListCache = {};
  final Map<String, String> _estadoErrors = {};
  final Map<String, bool> _fetchingEstado = {};
  final Map<String, bool> _loadingEstado = {};
  // Historial local (persistido en SharedPreferences)
  final List<Map<String, dynamic>> _historial = [];

  List<Map<String, dynamic>> get historial => List.unmodifiable(_historial);

  static const String _historialKey = 'inventario_historial_v1';

  InventarioProvider() {
    _loadHistorial();
  }

  Map<String, int> get estadosResumen => _estadosResumen;
  String? getEstadoError(String tipo) => _estadoErrors[tipo];

  bool isLoadingEstado(String tipo) => _loadingEstado[tipo] ?? false;

  List<Map<String, dynamic>> getEstadoList(String tipo) =>
      _estadosListCache[tipo] ?? [];

  Future<void> cargarResumenEstados() async {
    try {
      final uri = Uri.parse('${ApiConfig.inventario}/estados/summary');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _estadosResumen = data.map((k, v) => MapEntry(k, (v as num).toInt()));
        notifyListeners();
      } else {
        debugPrint(
            'Error cargando resumen de estados: HTTP ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout cargando resumen de estados: $e');
    } on SocketException catch (e) {
      debugPrint('Network error cargando resumen de estados: $e');
    } catch (e) {
      debugPrint('Error cargando resumen de estados: $e');
    }
  }

  Future<List<Map<String, dynamic>>> cargarListaEstado(String tipo) async {
    // If we already have a cached value, return it immediately to avoid
    // keeping the UI in a permanent loading state. Then refresh in
    // background to update the cache.
    final cached = _estadosListCache[tipo];
    if (cached != null) {
      // Return cached immediately. Trigger a background refresh only if
      // one isn't already running.
      if (!(_fetchingEstado[tipo] ?? false)) {
        _loadingEstado[tipo] = true;
        notifyListeners();
        _fetchListaEstado(tipo);
      }
      return Future.value(cached);
    }

    // No cache at all: start fetch in background but return immediately so
    // the UI can render synchronously and rely on provider.isLoadingEstado
    // to show a spinner.
    if (!(_fetchingEstado[tipo] ?? false)) {
      _loadingEstado[tipo] = true;
      notifyListeners();
      _fetchListaEstado(tipo);
    }
    return Future.value(_estadosListCache[tipo] ?? []);
  }

  // Internal helper that performs the network fetch and updates cache.
  Future<List<Map<String, dynamic>>> _fetchListaEstado(String tipo) async {
    // Avoid concurrent fetches for the same 'tipo'.
    if (_fetchingEstado[tipo] == true) {
      // Another fetch is in progress; wait a short time for it to complete
      // and then return the cached value (if any) to avoid piling up
      // concurrent requests.
      await Future.delayed(const Duration(milliseconds: 200));
      return _estadosListCache[tipo] ?? [];
    }
    _fetchingEstado[tipo] = true;
    _loadingEstado[tipo] = true;
    notifyListeners();
    try {
      _estadoErrors.remove(tipo);
      final uri = Uri.parse('${ApiConfig.inventario}/estados/list/$tipo');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _estadosListCache[tipo] = list;
        _fetchingEstado[tipo] = false;
        _loadingEstado[tipo] = false;
        notifyListeners();
        return list;
      } else {
        _estadoErrors[tipo] = 'HTTP ${response.statusCode}';
        debugPrint(
            'Error cargando lista de estado $tipo: HTTP ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _estadoErrors[tipo] = 'Timeout';
      debugPrint('Timeout cargando lista de estado $tipo: $e');
    } on SocketException catch (e) {
      _estadoErrors[tipo] = 'Network';
      debugPrint('Network error cargando lista de estado $tipo: $e');
    } catch (e) {
      _estadoErrors[tipo] = 'Error';
      debugPrint('Error cargando lista de estado $tipo: $e');
    }
    notifyListeners();
    _fetchingEstado[tipo] = false;
    _loadingEstado[tipo] = false;
    return _estadosListCache[tipo] ?? [];
  }

  Future<void> cargarArticulos() async {
    debugPrint('InventarioProvider.cargarArticulos: start');
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.inventario}/articulos'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _articulos = data.map((json) => Articulo.fromJson(json)).toList();
        _addHistorialEntry('sync', 'Sincronización de artículos',
            data: {'count': _articulos.length});
      }
    } catch (e) {
      debugPrint('Error cargando artículos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint(
          'InventarioProvider.cargarArticulos: done, count=${_articulos.length}');
    }
  }

  Future<void> cargarTrajes() async {
    debugPrint('InventarioProvider.cargarTrajes: start');
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.inventario}/trajes'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _trajes = data.map((json) => Traje.fromJson(json)).toList();
        notifyListeners();
        debugPrint(
            'InventarioProvider.cargarTrajes: done, count=${_trajes.length}');
        _addHistorialEntry('sync', 'Sincronización de trajes',
            data: {'count': _trajes.length});
      }
    } catch (e) {
      debugPrint('Error cargando trajes: $e');
    }
  }

  Future<Traje?> obtenerTrajePorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.inventario}/trajes/$id'),
      );

      if (response.statusCode == 200) {
        return Traje.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo traje: $e');
      return null;
    }
  }

  Future<bool> actualizarArticulo(String id, Articulo articulo) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.inventario}/articulos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(articulo.toJson()),
      );

      if (response.statusCode == 200) {
        await cargarArticulos();
        _addHistorialEntry('update', 'Artículo actualizado',
            data: {'id': id, 'nombre': articulo.nombre});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error actualizando artículo: $e');
      return false;
    }
  }

  Future<bool> cambiarEstadoArticulo(String id, String estado) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.inventario}/articulos/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'estado': estado}),
      );

      if (response.statusCode == 200) {
        await cargarArticulos();
        _addHistorialEntry('estado', 'Cambio de estado',
            data: {'id': id, 'estado': estado});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cambiando estado: $e');
      return false;
    }
  }

  Future<bool> gestionarMantenimiento(
      String id,
      String accion, // 'agregar' o 'quitar'
      int cantidad,
      {int? horasMantenimiento,
      bool indefinido = false}) async {
    try {
      final body = {
        'accion': accion,
        'cantidad': cantidad,
        'indefinido': indefinido,
      };

      if (horasMantenimiento != null) {
        body['horas_mantenimiento'] = horasMantenimiento;
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.inventario}/articulos/$id/mantenimiento'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        await cargarArticulos();
        _addHistorialEntry('mantenimiento', 'Mantenimiento $accion', data: {
          'id': id,
          'accion': accion,
          'cantidad': cantidad,
          'horas': horasMantenimiento,
          'indefinido': indefinido
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error gestionando mantenimiento: $e');
      return false;
    }
  }

  Future<bool> eliminarArticulo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.inventario}/articulos/$id'),
      );

      if (response.statusCode == 200) {
        await cargarArticulos();
        _addHistorialEntry('delete', 'Artículo eliminado', data: {'id': id});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error eliminando artículo: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> crearArticulo(Articulo articulo) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.inventario}/articulos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(articulo.toJson()),
      );

      if (response.statusCode == 201) {
        final created = json.decode(response.body) as Map<String, dynamic>;
        await cargarArticulos();
        _addHistorialEntry('create', 'Artículo creado', data: {
          'id': created['id'],
          'nombre': articulo.nombre,
          'cantidad': articulo.cantidad
        });
        return {'success': true};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error desconocido'
        };
      }
    } catch (e) {
      debugPrint('Error creando artículo: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> crearTraje(
      String nombre, String descripcion, List<String> articulosIds) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.inventario}/trajes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre,
          'descripcion': descripcion,
          'articulos': articulosIds,
        }),
      );

      if (response.statusCode == 201) {
        await cargarTrajes();
        _addHistorialEntry('create_traje', 'Traje creado',
            data: {'nombre': nombre, 'articulos': articulosIds});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creando traje: $e');
      return false;
    }
  }

  Future<bool> eliminarTraje(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.inventario}/trajes/$id'),
      );

      if (response.statusCode == 200) {
        await cargarTrajes();
        _addHistorialEntry('delete_traje', 'Traje eliminado', data: {'id': id});
        return true;
      }
      debugPrint('Error eliminando traje: HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error eliminando traje: $e');
      return false;
    }
  }

  // Historial helpers
  Future<void> _loadHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historialKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        _historial.clear();
        for (final e in decoded) {
          _historial.add(Map<String, dynamic>.from(e));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    }
  }

  Future<void> _saveHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historialKey, json.encode(_historial));
    } catch (e) {
      debugPrint('Error guardando historial: $e');
    }
  }

  void _addHistorialEntry(String tipo, String mensaje,
      {Map<String, dynamic>? data}) {
    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'tipo': tipo,
      'mensaje': mensaje,
      'data': data ?? {}
    };
    _historial.insert(0, entry);
    if (_historial.length > 1000)
      _historial.removeRange(1000, _historial.length);
    notifyListeners();
    _saveHistorial();
  }

  Future<void> clearHistorial() async {
    _historial.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historialKey);
  }
}
