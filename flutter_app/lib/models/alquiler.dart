import 'cliente.dart';
import 'articulo.dart';

class Alquiler {
  final String? id;
  final String clienteId;
  final Cliente? cliente;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final DateTime? fechaDevolucion;
  final double montoAlquiler;
  //final double? totalFinal;
  final double garantia;
  final double garantiaRetenida;
  final double moraCobrada;
  final String metodoPago;
  final String? observaciones;
  final String? descripcionRetencion;
  final String estado; // 'activo', 'devuelto', 'perdido'
  final List<AlquilerArticulo> articulos;

  Alquiler({
    this.id,
    required this.clienteId,
    this.cliente,
    required this.fechaInicio,
    required this.fechaFin,
    this.fechaDevolucion,
    required this.montoAlquiler,
    //this.totalFinal,
    required this.garantia,
    this.garantiaRetenida = 0,
    this.moraCobrada = 0,
    required this.metodoPago,
    this.observaciones,
    this.descripcionRetencion,
    this.estado = 'activo',
    this.articulos = const [],
  });

  factory Alquiler.fromJson(Map<String, dynamic> json) {
    List<AlquilerArticulo> arts = [];
    if (json['alquiler_articulos'] != null) {
      arts = (json['alquiler_articulos'] as List)
          .map((aa) => AlquilerArticulo.fromJson(aa))
          .toList();
    }

    Cliente? cli;
    if (json['clientes'] != null) {
      cli = Cliente.fromJson(json['clientes']);
    }

    return Alquiler(
      id: json['id'],
      clienteId: json['cliente_id'],
      cliente: cli,
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      fechaDevolucion: json['fecha_devolucion'] != null
          ? DateTime.parse(json['fecha_devolucion'])
          : null,
      montoAlquiler: double.parse(json['monto_alquiler'].toString()),
      /*totalFinal: json['total_final'] != null
          ? (json['total_final'] as num).toDouble()
          : null,*/
      garantia: double.parse(json['garantia'].toString()),
      garantiaRetenida: double.parse(
        json['garantia_retenida']?.toString() ?? '0',
      ),
      moraCobrada: double.parse(json['mora_cobrada']?.toString() ?? '0'),
      metodoPago: json['metodo_pago'],
      observaciones: json['observaciones'],
      descripcionRetencion: json['descripcion_retencion'],
      estado: json['estado'] ?? 'activo',
      articulos: arts,
    );
  }

  /*factory Alquiler.fromJson(Map<String, dynamic> json) {
    // 1. DEBUG: Esto imprimirá en tu consola qué está llegando realmente.
    // Si ves esto en la consola, sabremos si el backend envía los datos.
    if (json['estado'] == 'devuelto') {
      print('--- DEBUG ALQUILER ${json['id']} ---');
      print('Monto Base: ${json['monto_alquiler']}');
      print('Mora (columna mora): ${json['mora']}');
      print('Total Final (backend): ${json['total_final']}');
    }

    List<AlquilerArticulo> arts = [];
    if (json['alquiler_articulos'] != null) {
      arts = (json['alquiler_articulos'] as List)
          .map((aa) => AlquilerArticulo.fromJson(aa))
          .toList();
    }

    Cliente? cli;
    if (json['clientes'] != null) {
      cli = Cliente.fromJson(json['clientes']);
    }

    // --- LÓGICA ROBUSTA PARA LEER MORA ---
    // Buscamos 'mora' (nombre estándar en BD) O 'mora_cobrada'
    double moraCalculada = 0.0;
    if (json['mora'] != null) {
      moraCalculada = (json['mora'] as num).toDouble();
    } else if (json['mora_cobrada'] != null) {
      moraCalculada = (json['mora_cobrada'] as num).toDouble();
    }

    // --- LÓGICA ROBUSTA PARA LEER TOTAL ---
    // 1. Intentamos leer lo que manda el backend
    double? totalFinalBackend;
    if (json['total_final'] != null) {
      totalFinalBackend = (json['total_final'] as num).toDouble();
    } else {
      // 2. Si el backend mandó null, lo calculamos aquí mismo (Plan B)
      double base = (json['monto_alquiler'] as num).toDouble();
      totalFinalBackend = base + moraCalculada;
    }

    return Alquiler(
      id: json['id'],
      clienteId: json['cliente_id'],
      cliente: cli,
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      fechaDevolucion: json['fecha_devolucion'] != null
          ? DateTime.parse(json['fecha_devolucion'])
          : null,
      montoAlquiler: double.parse(json['monto_alquiler'].toString()),

      // AQUI ASIGNAMOS EL VALOR CALCULADO O RECIBIDO
      totalFinal: totalFinalBackend,

      garantia: double.parse(json['garantia'].toString()),
      garantiaRetenida: double.parse(
        json['garantia_retenida']?.toString() ?? '0',
      ),

      // Asignamos la mora que encontramos (ya sea 'mora' o 'mora_cobrada')
      moraCobrada: moraCalculada,

      metodoPago: json['metodo_pago'],
      observaciones: json['observaciones'],
      descripcionRetencion: json['descripcion_retencion'],
      estado: json['estado'] ?? 'activo',
      articulos: arts,
    );
  }*/

  Map<String, dynamic> toJson() {
    return {
      'cliente_id': clienteId,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'fecha_fin': fechaFin.toIso8601String().split('T')[0],
      'monto_alquiler': montoAlquiler,
      'garantia': garantia,
      'metodo_pago': metodoPago,
      'observaciones': observaciones,
      'articulos': articulos.map((a) => {'id': a.articuloId}).toList(),
    };
  }

  bool get isActivo => estado == 'activo';
  bool get isDevuelto => estado == 'devuelto';

  bool get isMoraVencida {
    if (fechaDevolucion != null) return false;
    return DateTime.now().isAfter(fechaFin);
  }

  int get diasMora {
    if (!isMoraVencida) return 0;
    return DateTime.now().difference(fechaFin).inDays;
  }
}

class AlquilerArticulo {
  final String? id;
  final String alquilerId;
  final String articuloId;
  final Articulo? articulo;
  final String estado; // 'alquilado', 'completo', 'dañado', 'perdido'

  AlquilerArticulo({
    this.id,
    required this.alquilerId,
    required this.articuloId,
    this.articulo,
    this.estado = 'alquilado',
  });

  factory AlquilerArticulo.fromJson(Map<String, dynamic> json) {
    Articulo? art;
    if (json['articulos'] != null) {
      art = Articulo.fromJson(json['articulos']);
    }

    return AlquilerArticulo(
      id: json['id'],
      alquilerId: json['alquiler_id'],
      articuloId: json['articulo_id'],
      articulo: art,
      estado: json['estado'] ?? 'alquilado',
    );
  }
}
