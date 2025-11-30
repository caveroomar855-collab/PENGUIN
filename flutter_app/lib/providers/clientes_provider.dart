import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cliente.dart';
import '../config/api_config.dart';

class ClientesProvider extends ChangeNotifier {
  List<Cliente> _clientes = [];
  List<Cliente> _clientesPapelera = [];
  bool _isLoading = false;

  List<Cliente> get clientes => _clientes;
  List<Cliente> get clientesPapelera => _clientesPapelera;
  bool get isLoading => _isLoading;

  Future<void> cargarClientes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(ApiConfig.clientes));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _clientes = data.map((json) => Cliente.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando clientes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPapelera() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.clientes}/papelera'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _clientesPapelera = data.map((json) => Cliente.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando papelera: $e');
    }
  }

  Future<Cliente?> buscarPorDni(String dni) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.clientes}/dni/$dni'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null) {
          return Cliente.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error buscando cliente: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> crearCliente(Cliente cliente) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.clientes),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cliente.toJson()),
      );

      if (response.statusCode == 201) {
        await cargarClientes();
        return {
          'success': true,
          'cliente': Cliente.fromJson(json.decode(response.body))
        };
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        return {'success': false, 'error': error};
      }
      return {'success': false, 'error': 'Error desconocido'};
    } catch (e) {
      debugPrint('Error creando cliente: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> actualizarCliente(String id, Cliente cliente) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.clientes}/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cliente.toJson()),
      );

      if (response.statusCode == 200) {
        await cargarClientes();
        return true;
      } else if (response.statusCode == 400) {
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error actualizando cliente: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> enviarAPapelera(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.clientes}/$id/papelera'),
      );

      if (response.statusCode == 200) {
        await cargarClientes();
        await cargarPapelera();
        return {'success': true};
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        return {'success': false, 'error': error['error']};
      }
      return {'success': false, 'error': 'Error desconocido'};
    } catch (e) {
      debugPrint('Error enviando a papelera: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> restaurarDePapelera(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.clientes}/$id/restaurar'),
      );

      if (response.statusCode == 200) {
        await cargarClientes();
        await cargarPapelera();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error restaurando de papelera: $e');
      return false;
    }
  }

  Future<bool> eliminarPermanentemente(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.clientes}/$id'),
      );

      if (response.statusCode == 200) {
        await cargarPapelera();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error eliminando cliente: $e');
      return false;
    }
  }
}
