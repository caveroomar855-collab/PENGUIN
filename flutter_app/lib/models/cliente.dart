class Cliente {
  final String? id;
  final String dni;
  final String nombre;
  final String telefono;
  final String? email;
  final String? descripcion;
  final bool enPapelera;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cliente({
    this.id,
    required this.dni,
    required this.nombre,
    required this.telefono,
    this.email,
    this.descripcion,
    this.enPapelera = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      dni: json['dni'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      descripcion: json['descripcion'],
      enPapelera: json['en_papelera'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dni': dni,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'descripcion': descripcion,
      'en_papelera': enPapelera,
    };
  }
}
