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

  Future<bool> crearArticulo(Articulo articulo) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.inventario}/articulos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(articulo.toJson()),
      );

      if (response.statusCode == 201) {
        await cargarArticulos();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creando artículo: $e');
      return false;
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

  Future<bool> cambiarEstadoMantenimiento(
    String id,
    String estado, {
    int? horasMantenimiento,
    bool indefinido = false,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.inventario}/articulos/$id/mantenimiento'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'estado': estado,
          'horas_mantenimiento': horasMantenimiento,
          'indefinido': indefinido,
        }),
      );

      if (response.statusCode == 200) {
        await cargarArticulos();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cambiando estado de mantenimiento: $e');
      return false;
    }
  }

  Future<bool> crearTraje(Traje traje) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.inventario}/trajes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(traje.toJson()),
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
