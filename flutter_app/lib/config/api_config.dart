class ApiConfig {
  // Cambia esta URL a la IP de tu servidor local
  // Si usas el emulador de Android: 10.0.2.2
  // Si usas dispositivo físico: la IP de tu computadora en la red local (ej: 192.168.1.100)
  static const String baseUrl = 'http://192.168.0.103:3000/api';

  // Endpoints
  static const String clientes = '$baseUrl/clientes';
  static const String alquileres = '$baseUrl/alquileres';
  static const String ventas = '$baseUrl/ventas';
  static const String inventario = '$baseUrl/inventario';
  static const String reportes = '$baseUrl/reportes';
  static const String configuracion = '$baseUrl/configuracion';
}
