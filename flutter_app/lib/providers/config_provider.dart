import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/configuracion.dart';
import '../config/api_config.dart';

class ConfigProvider extends ChangeNotifier {
  Configuracion? _configuracion;
  bool _isLoading = false;

  Configuracion? get configuracion => _configuracion;
  bool get isLoading => _isLoading;

  Future<void> cargarConfiguracion() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.configuracion),
      );

      if (response.statusCode == 200) {
        _configuracion = Configuracion.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error cargando configuración: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarConfiguracion(Configuracion config) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.configuracion),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      );

      if (response.statusCode == 200) {
        _configuracion = Configuracion.fromJson(json.decode(response.body));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error actualizando configuración: $e');
      return false;
    }
  }
}
