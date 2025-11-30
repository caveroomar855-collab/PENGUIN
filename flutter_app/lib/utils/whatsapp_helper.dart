import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class WhatsappHelper {
  // --- MÉTODO 1: Para Alquileres y Contacto General ---
  static Future<void> enviarRecordatorio({
    required BuildContext context,
    required String telefono,
    required String nombreCliente,
    required String fechaVencimiento,
    bool esRecordatorio = true, // true para cobro, false para contacto general
  }) async {
    _lanzarWhatsApp(
      context: context,
      telefono: telefono,
      mensaje: esRecordatorio
          ? "Hola *$nombreCliente*, le saludamos desde Penguin Ternos, nuestra tienda de alquiler y venta de ternos. \n\n"
              "[!] Le recordamos que su alquiler vence el día *$fechaVencimiento*. "
              "Por favor tomar las precauciones para la devolución."
          : "Hola *$nombreCliente*, le escribimos desde Penguin Ternos, nuestra tienda de alquiler y venta de ternos, para consultarle...",
    );
  }

  // --- MÉTODO 2: Nuevo para Citas ---
  static Future<void> enviarRecordatorioCita({
    required BuildContext context,
    required String telefono,
    required String nombreCliente,
    required String fechaHoraCita,
  }) async {
    _lanzarWhatsApp(
      context: context,
      telefono: telefono,
      mensaje: "Hola *$nombreCliente*, le saludamos desde Penguin Ternos. \n\n"
          "🗓️ Le recordamos que tiene una cita programada para el *$fechaHoraCita*. "
          "¡Los esperamos!",
    );
  }

  // --- Lógica interna reutilizable (Privada) ---
  static Future<void> _lanzarWhatsApp({
    required BuildContext context,
    required String telefono,
    required String mensaje,
  }) async {
    // 1. Limpieza del número (Asumiendo Perú +51)
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (!telefonoLimpio.startsWith('51') && telefonoLimpio.length == 9) {
      telefonoLimpio = '51$telefonoLimpio';
    }

    // 2. Crear URL
    final Uri url = Uri.parse(
        "https://wa.me/$telefonoLimpio?text=${Uri.encodeComponent(mensaje)}");

    // 3. Lanzar
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo abrir WhatsApp (¿Está instalado?)')),
        );
      }
    }
  }
}
