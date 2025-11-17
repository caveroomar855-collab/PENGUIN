class ApiConfig {
  // Backend deployado en Render - Nadie necesita correr servidor local
  static const String baseUrl = 'https://penguin-kt7e.onrender.com/api';

  // Endpoints
  static const String clientes = '$baseUrl/clientes';
  static const String alquileres = '$baseUrl/alquileres';
  static const String ventas = '$baseUrl/ventas';
  static const String inventario = '$baseUrl/inventario';
  static const String reportes = '$baseUrl/reportes';
  static const String configuracion = '$baseUrl/configuracion';
}
