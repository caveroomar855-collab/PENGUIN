class Articulo {
  final String? id;
  final String codigo;
  final String nombre;
  final String
  tipo; // 'saco', 'chaleco', 'pantalon', 'camisa', 'zapato', 'extra'
  final String? talla;
  final String? color;
  final double precioAlquiler;
  final double precioVenta;
  final String
  estado; // 'disponible', 'alquilado', 'mantenimiento', 'vendido', 'perdido'
  final DateTime? fechaDisponible;

  Articulo({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.talla,
    this.color,
    required this.precioAlquiler,
    required this.precioVenta,
    this.estado = 'disponible',
    this.fechaDisponible,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      talla: json['talla'],
      color: json['color'],
      precioAlquiler: double.parse(json['precio_alquiler'].toString()),
      precioVenta: double.parse(json['precio_venta'].toString()),
      estado: json['estado'] ?? 'disponible',
      fechaDisponible: json['fecha_disponible'] != null
          ? DateTime.parse(json['fecha_disponible'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'talla': talla,
      'color': color,
      'precio_alquiler': precioAlquiler,
      'precio_venta': precioVenta,
      'estado': estado,
      'fecha_disponible': fechaDisponible?.toIso8601String(),
    };
  }

  bool get isDisponible => estado == 'disponible';
  bool get isAlquilado => estado == 'alquilado';
  bool get isMantenimiento => estado == 'mantenimiento';
}
