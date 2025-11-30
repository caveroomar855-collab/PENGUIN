import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cita.dart';
import '../config/api_config.dart';

class CitasProvider extends ChangeNotifier {
  List<Cita> _citas = [];
  List<Cita> _citasPendientes = [];
  bool _isLoading = false;

  List<Cita> get citas => _citas;
  List<Cita> get citasPendientes => _citasPendientes;
  bool get isLoading => _isLoading;

  Future<void> cargarCitas() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/citas'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _citas = data.map((json) => Cita.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando citas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarCitasPendientes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/citas/pendientes'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _citasPendientes = data.map((json) => Cita.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando citas pendientes: $e');
    }
  }

  Future<Map<String, dynamic>> crearCita(Cita cita) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/citas'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cita.toJson()),
      );

      if (response.statusCode == 201) {
        await cargarCitas();
        await cargarCitasPendientes();
        return {
          'success': true,
          'cita': Cita.fromJson(json.decode(response.body))
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error desconocido'
        };
      }
    } catch (e) {
      debugPrint('Error creando cita: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> actualizarEstado(String id, String estado) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/citas/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'estado': estado}),
      );

      if (response.statusCode == 200) {
        await cargarCitas();
        await cargarCitasPendientes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error actualizando cita: $e');
      return false;
    }
  }

  Future<bool> eliminarCita(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/citas/$id'),
      );

      if (response.statusCode == 200) {
        await cargarCitas();
        await cargarCitasPendientes();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error eliminando cita: $e');
      return false;
    }
  }
}
