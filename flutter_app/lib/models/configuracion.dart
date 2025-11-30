class Configuracion {
  final String? id;
  final String nombreEmpleado;
  final bool temaOscuro;
  final double garantiaDefault;
  final double moraDiaria;
  final int diasMaximosMora;

  Configuracion({
    this.id,
    required this.nombreEmpleado,
    required this.temaOscuro,
    required this.garantiaDefault,
    required this.moraDiaria,
    required this.diasMaximosMora,
  });

  factory Configuracion.fromJson(Map<String, dynamic> json) {
    return Configuracion(
      id: json['id'],
      nombreEmpleado: json['nombre_empleado'] ?? 'Empleado',
      temaOscuro: json['tema_oscuro'] ?? false,
      garantiaDefault: double.parse(
        json['garantia_default']?.toString() ?? '50.0',
      ),
      moraDiaria: double.parse(json['mora_diaria']?.toString() ?? '10.0'),
      diasMaximosMora: json['dias_maximos_mora'] ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_empleado': nombreEmpleado,
      'tema_oscuro': temaOscuro,
      'garantia_default': garantiaDefault,
      'mora_diaria': moraDiaria,
      'dias_maximos_mora': diasMaximosMora,
    };
  }

  Configuracion copyWith({
    String? nombreEmpleado,
    bool? temaOscuro,
    double? garantiaDefault,
    double? moraDiaria,
    int? diasMaximosMora,
  }) {
    return Configuracion(
      id: id,
      nombreEmpleado: nombreEmpleado ?? this.nombreEmpleado,
      temaOscuro: temaOscuro ?? this.temaOscuro,
      garantiaDefault: garantiaDefault ?? this.garantiaDefault,
      moraDiaria: moraDiaria ?? this.moraDiaria,
      diasMaximosMora: diasMaximosMora ?? this.diasMaximosMora,
    );
  }
}
