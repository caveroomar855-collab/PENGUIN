import 'articulo.dart';

class Traje {
  final String? id;
  final String nombre;
  final String? descripcion;
  final List<Articulo> articulos;

  Traje({
    this.id,
    required this.nombre,
    this.descripcion,
    this.articulos = const [],
  });

  factory Traje.fromJson(Map<String, dynamic> json) {
    List<Articulo> arts = [];
    if (json['traje_articulos'] != null) {
      arts = (json['traje_articulos'] as List)
          .map((ta) => Articulo.fromJson(ta['articulos']))
          .toList();
    }

    return Traje(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      articulos: arts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'articulos': articulos.map((a) => a.id).toList(),
    };
  }

  bool get isDisponible => articulos.every((a) => a.isDisponible);
  int get articulosDisponibles => articulos.where((a) => a.isDisponible).length;
}
