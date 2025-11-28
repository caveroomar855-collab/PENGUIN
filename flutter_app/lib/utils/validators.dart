class Validators {
  // Validar DNI (exactamente 8 dígitos)
  static String? validateDni(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI es obligatorio';
    }
    if (value.length != 8) {
      return 'El DNI debe tener 8 dígitos';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'El DNI solo debe contener números';
    }
    return null;
  }

  // Validar teléfono (9 dígitos, empieza con 9)
  static String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    if (value.length != 9) {
      return 'El teléfono debe tener 9 dígitos';
    }
    if (!value.startsWith('9')) {
      return 'El teléfono debe empezar con 9';
    }
    if (!RegExp(r'^\d{9}$').hasMatch(value)) {
      return 'El teléfono solo debe contener números';
    }
    return null;
  }

  // Validar nombre (no vacío, solo letras y espacios)
  static String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo debe contener letras';
    }
    return null;
  }

  // Código de artículo eliminado — ya no se usa en la app

  // Validar precio (número positivo)
  static String? validatePrecio(String? value) {
    if (value == null || value.isEmpty) {
      return 'El precio es obligatorio';
    }
    final precio = double.tryParse(value);
    if (precio == null) {
      return 'Ingrese un precio válido';
    }
    if (precio <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    return null;
  }

  // Validar cantidad (número entero positivo)
  static String? validateCantidad(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cantidad es obligatoria';
    }
    final cantidad = int.tryParse(value);
    if (cantidad == null) {
      return 'Ingrese una cantidad válida';
    }
    if (cantidad <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    return null;
  }

  // Validar email (formato correcto)
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email es opcional en la mayoría de casos
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingrese un email válido';
    }
    return null;
  }
}
