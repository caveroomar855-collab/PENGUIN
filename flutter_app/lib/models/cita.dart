class Cita {
  final String? id;
  final String clienteId;
  final DateTime fechaHora;
  final String tipo; // 'alquiler', 'prueba', 'devolucion', 'otro'
  final String? descripcion;
  final String estado; // 'pendiente', 'completada', 'cancelada'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Datos del cliente (si viene del backend)
  final String? clienteDni;
  final String? clienteNombre;
  final String? clienteTelefono;

  Cita({
    this.id,
    required this.clienteId,
    required this.fechaHora,
    required this.tipo,
    this.descripcion,
    this.estado = 'pendiente',
    this.createdAt,
    this.updatedAt,
    this.clienteDni,
    this.clienteNombre,
    this.clienteTelefono,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      clienteId: json['cliente_id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'pendiente',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      clienteDni: json['clientes']?['dni'],
      clienteNombre: json['clientes']?['nombre'],
      clienteTelefono: json['clientes']?['telefono'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cliente_id': clienteId,
      'fecha_hora': fechaHora.toIso8601String(),
      'tipo': tipo,
      'descripcion': descripcion,
      'estado': estado,
    };
  }

  bool get esPendiente => estado == 'pendiente';
  bool get esCompletada => estado == 'completada';
  bool get esCancelada => estado == 'cancelada';
  bool get esFutura => fechaHora.isAfter(DateTime.now());
}
