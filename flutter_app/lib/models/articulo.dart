class Articulo {
  final String? id;
  final String nombre;
  final String
      tipo; // 'saco', 'chaleco', 'pantalon', 'camisa', 'zapato', 'extra'
  final String? talla;
  // color removed per client request
  final double precioAlquiler;
  final double precioVenta;
  final String
      estado; // 'disponible', 'alquilado', 'mantenimiento', 'vendido', 'perdido'
  final DateTime? fechaDisponible;
  final int cantidad;
  final int cantidadDisponible;
  final int cantidadAlquilada;
  final int cantidadMantenimiento;
  final int cantidadVendida;
  final int cantidadPerdida;

  Articulo({
    this.id,
    required this.nombre,
    required this.tipo,
    this.talla,
    required this.precioAlquiler,
    required this.precioVenta,
    this.estado = 'disponible',
    this.fechaDisponible,
    this.cantidad = 1,
    this.cantidadDisponible = 1,
    this.cantidadAlquilada = 0,
    this.cantidadMantenimiento = 0,
    this.cantidadVendida = 0,
    this.cantidadPerdida = 0,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      id: json['id'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      talla: json['talla'],
      precioAlquiler: double.parse(json['precio_alquiler'].toString()),
      precioVenta: double.parse(json['precio_venta'].toString()),
      estado: json['estado'] ?? 'disponible',
      fechaDisponible: json['fecha_disponible'] != null
          ? DateTime.parse(json['fecha_disponible'])
          : null,
      cantidad: json['cantidad'] ?? 1,
      cantidadDisponible: json['cantidad_disponible'] ?? 1,
      cantidadAlquilada: json['cantidad_alquilada'] ?? 0,
      cantidadMantenimiento: json['cantidad_mantenimiento'] ?? 0,
      cantidadVendida: json['cantidad_vendida'] ?? 0,
      cantidadPerdida: json['cantidad_perdida'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'talla': talla,
      'precio_alquiler': precioAlquiler,
      'precio_venta': precioVenta,
      'estado': estado,
      'fecha_disponible': fechaDisponible?.toIso8601String(),
      'cantidad': cantidad,
    };
  }

  bool get isDisponible => cantidadDisponible > 0;
  bool get isAlquilado => cantidadAlquilada > 0;
  bool get isMantenimiento => cantidadMantenimiento > 0;
  bool get tieneStock => cantidadDisponible > 0;
}
