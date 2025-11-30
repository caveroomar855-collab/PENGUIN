import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsappHelper {
  static Future<void> enviarRecordatorio({
    required BuildContext context,
    required String telefono,
    required String nombreCliente,
    required String fechaVencimiento,
    bool esRecordatorio = true, // true para cobro, false para contacto general
  }) async {
    // 1. Limpieza del número (Asumiendo Perú +51)
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (!telefonoLimpio.startsWith('51') && telefonoLimpio.length == 9) {
      telefonoLimpio = '51$telefonoLimpio';
    }

    // 2. Mensaje Personalizado
    String mensaje;
    if (esRecordatorio) {
      mensaje =
          "Hola *$nombreCliente*, le saludamos de la tienda de alquiler de Ternos. \n\n"
          "[!] Le recordamos que su alquiler vence el día *$fechaVencimiento*. "
          "Por favor tomar las precauciones para la devolución.";
    } else {
      mensaje =
          "Hola *$nombreCliente*, le escribimos de la tienda de Ternos para consultarle...";
    }

    // 3. Lanzar WhatsApp
    final Uri url = Uri.parse(
        "https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo abrir WhatsApp (¿Está instalado?)')),
      );
    }
  }
}
