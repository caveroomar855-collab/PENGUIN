import 'cliente.dart';
import 'articulo.dart';

class Venta {
  final String? id;
  final String clienteId;
  final Cliente? cliente;
  final double total;
  final String metodoPago;
  final String estado; // 'completada', 'devuelta'
  final DateTime? fechaDevolucion;
  final DateTime? createdAt;
  final List<VentaArticulo> articulos;

  Venta({
    this.id,
    required this.clienteId,
    this.cliente,
    required this.total,
    required this.metodoPago,
    this.estado = 'completada',
    this.fechaDevolucion,
    this.createdAt,
    this.articulos = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    List<VentaArticulo> arts = [];
    if (json['venta_articulos'] != null) {
      arts = (json['venta_articulos'] as List)
          .map((va) => VentaArticulo.fromJson(va))
          .toList();
    }

    Cliente? cli;
    if (json['clientes'] != null) {
      cli = Cliente.fromJson(json['clientes']);
    }

    return Venta(
      id: json['id'],
      clienteId: json['cliente_id'],
      cliente: cli,
      total: double.parse(json['total'].toString()),
      metodoPago: json['metodo_pago'],
      estado: json['estado'] ?? 'completada',
      fechaDevolucion: json['fecha_devolucion'] != null
          ? DateTime.parse(json['fecha_devolucion'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      articulos: arts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cliente_id': clienteId,
      'total': total,
      'metodo_pago': metodoPago,
      'articulos': articulos
          .map((a) => {
                'id': a.articuloId,
                'precio_venta': a.precio,
                'cantidad': a.cantidad
              })
          .toList(),
    };
  }

  bool get isCompletada => estado == 'completada';
  bool get isDevuelta => estado == 'devuelta';

  bool get puedeDevolver {
    if (createdAt == null || isDevuelta) return false;
    final diasTranscurridos = DateTime.now().difference(createdAt!).inDays;
    return diasTranscurridos <= 3;
  }
}

class VentaArticulo {
  final String? id;
  final String ventaId;
  final String articuloId;
  final Articulo? articulo;
  final double precio;
  final int cantidad;

  VentaArticulo({
    this.id,
    required this.ventaId,
    required this.articuloId,
    this.articulo,
    required this.precio,
    this.cantidad = 1,
  });

  factory VentaArticulo.fromJson(Map<String, dynamic> json) {
    Articulo? art;
    if (json['articulos'] != null) {
      art = Articulo.fromJson(json['articulos']);
    }

    return VentaArticulo(
      id: json['id'],
      ventaId: json['venta_id'],
      articuloId: json['articulo_id'],
      articulo: art,
      precio: double.parse(json['precio'].toString()),
      cantidad: json['cantidad'] ?? 1,
    );
  }
}
