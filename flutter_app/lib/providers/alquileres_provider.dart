import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/alquiler.dart';
import '../config/api_config.dart';

class AlquileresProvider extends ChangeNotifier {
  List<Alquiler> _alquileresActivos = [];
  List<Alquiler> _historial = [];
  bool _isLoading = false;

  List<Alquiler> get alquileresActivos => _alquileresActivos;
  List<Alquiler> get historial => _historial;
  bool get isLoading => _isLoading;

  Future<void> cargarActivos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.alquileres}/activos'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _alquileresActivos =
            data.map((json) => Alquiler.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando alquileres activos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarHistorial() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.alquileres}/historial'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _historial = data.map((json) => Alquiler.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    }
  }

  Future<Alquiler?> obtenerPorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.alquileres}/$id'),
      );

      if (response.statusCode == 200) {
        return Alquiler.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo alquiler: $e');
      return null;
    }
  }

  Future<bool> crearAlquiler({
    required String clienteId,
    required List<Map<String, dynamic>> articulos,
    required List<String> trajesIds,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double montoAlquiler,
    required double garantia,
  }) async {
    try {
      debugPrint('=== CREAR ALQUILER ===');
      debugPrint('Cliente ID: $clienteId');
      debugPrint('Artículos: $articulos');

      final body = {
        'cliente_id': clienteId,
        'articulos': articulos,
        'fecha_inicio': fechaInicio.toIso8601String(),
        'fecha_fin': fechaFin.toIso8601String(),
        'monto_alquiler': montoAlquiler,
        'garantia': garantia,
      };

      debugPrint('Body enviado: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(ApiConfig.alquileres),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        await cargarActivos();
        return true;
      }
      debugPrint('Error: Status ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error creando alquiler: $e');
      return false;
    }
  }

  Future<bool> marcarDevolucion(
    String id,
    List<Map<String, dynamic>> articulos,
    bool retenerGarantia,
    String? descripcion,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.alquileres}/$id/devolucion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'articulos': articulos,
          'retener_garantia': retenerGarantia,
          'descripcion_retencion': descripcion,
        }),
      );

      if (response.statusCode == 200) {
        await cargarActivos();
        await cargarHistorial();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marcando devolución: $e');
      return false;
    }
  }
}
