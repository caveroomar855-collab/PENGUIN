import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/venta.dart';
import '../config/api_config.dart';

class VentasProvider extends ChangeNotifier {
  List<Venta> _ventas = [];
  bool _isLoading = false;

  List<Venta> get ventas => _ventas;
  bool get isLoading => _isLoading;

  Future<void> cargarVentas() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(ApiConfig.ventas));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _ventas = data.map((json) => Venta.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando ventas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Venta?> obtenerPorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.ventas}/$id'),
      );

      if (response.statusCode == 200) {
        return Venta.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo venta: $e');
      return null;
    }
  }

  Future<bool> crearVenta(Venta venta) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.ventas),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(venta.toJson()),
      );

      if (response.statusCode == 201) {
        await cargarVentas();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creando venta: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> procesarDevolucion(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.ventas}/$id/devolucion'),
      );

      if (response.statusCode == 200) {
        await cargarVentas();
        return {'success': true};
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error']};
      }
      return {'success': false, 'error': 'Error desconocido'};
    } catch (e) {
      debugPrint('Error procesando devolución: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
