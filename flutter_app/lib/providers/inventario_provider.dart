import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> cargarArticulos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.inventario}/articulos'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _articulos = data.map((json) => Articulo.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando artículos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarTrajes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.inventario}/trajes'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _trajes = data.map((json) => Traje.fromJson(json)).toList();
        notifyListeners();
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
    {int? horasMantenimiento, bool indefinido = false}
  ) async {
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
        await cargarArticulos();
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
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creando traje: $e');
      return false;
    }
  }
}
