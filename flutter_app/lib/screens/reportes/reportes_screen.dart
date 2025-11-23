import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/api_config.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  String _tipoReporte = 'alquileres';
  bool _cargando = false;
  // _datosReporte removed because it's not read elsewhere; use local vars when needed.

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de Reporte',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _tipoReporte,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assessment),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'alquileres',
                          child: Text('Reporte de Alquileres')),
                      DropdownMenuItem(
                          value: 'ventas', child: Text('Reporte de Ventas')),
                      DropdownMenuItem(
                          value: 'inventario',
                          child: Text('Estado de Inventario')),
                      DropdownMenuItem(
                          value: 'clientes',
                          child: Text('Reporte de Clientes')),
                    ],
                    onChanged: (value) {
                      setState(() => _tipoReporte = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rango de Fechas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaInicio,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _fechaInicio = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha Inicio',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(dateFormat.format(_fechaInicio)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaFin,
                              firstDate: _fechaInicio,
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _fechaFin = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha Fin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event),
                            ),
                            child: Text(dateFormat.format(_fechaFin)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargando ? null : _generarReporte,
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_cargando ? 'Generando...' : 'Generar Reporte PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _cargando ? null : _verVistaPrevia,
            icon: const Icon(Icons.visibility),
            label: const Text('Ver Vista Previa'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reportes Rápidos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.today, color: Colors.blue),
                    title: const Text('Reporte del Día'),
                    subtitle: const Text('Alquileres y ventas de hoy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() {
                        _fechaInicio = DateTime.now();
                        _fechaFin = DateTime.now();
                      });
                      _verVistaPrevia();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.date_range, color: Colors.green),
                    title: const Text('Reporte Semanal'),
                    subtitle: const Text('Últimos 7 días'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() {
                        _fechaInicio =
                            DateTime.now().subtract(const Duration(days: 7));
                        _fechaFin = DateTime.now();
                      });
                      _verVistaPrevia();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.calendar_month, color: Colors.orange),
                    title: const Text('Reporte Mensual'),
                    subtitle: const Text('Últimos 30 días'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() {
                        _fechaInicio =
                            DateTime.now().subtract(const Duration(days: 30));
                        _fechaFin = DateTime.now();
                      });
                      _verVistaPrevia();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generarReporte() async {
    setState(() => _cargando = true);

    try {
      // Obtener datos del reporte
      final datos = await _obtenerDatosReporte();

      if (datos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al obtener datos del reporte'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Generar PDF
      final pdf = await _crearPDF(datos);

      // Mostrar diálogo de impresión/descarga
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name:
              'Reporte_${_getTituloReporte()}_${DateFormat('dd-MM-yyyy').format(_fechaInicio)}.pdf',
        );
      }
    } catch (e) {
      debugPrint('Error generando reporte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<Map<String, dynamic>?> _obtenerDatosReporte() async {
    try {
      final fechaInicioStr = DateFormat('yyyy-MM-dd').format(_fechaInicio);
      final fechaFinStr = DateFormat('yyyy-MM-dd')
          .format(_fechaFin.add(const Duration(days: 1)));

      String endpoint = '';
      if (_tipoReporte == 'alquileres') {
        endpoint = '${ApiConfig.reportes}/alquileres';
      } else if (_tipoReporte == 'ventas') {
        endpoint = '${ApiConfig.reportes}/ventas';
      } else {
        return null;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fecha_inicio': fechaInicioStr,
          'fecha_fin': fechaFinStr,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo datos: $e');
      return null;
    }
  }

  Future<pw.Document> _crearPDF(Map<String, dynamic> datos) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PENGUIN TERNOS',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'REPORTE DE ${_getTituloReporte().toUpperCase()}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Período: ${dateFormat.format(_fechaInicio)} - ${dateFormat.format(_fechaFin)}',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Tabla de datos
            if (_tipoReporte == 'alquileres')
              _construirTablaAlquileres(datos, dateFormat, currencyFormat)
            else if (_tipoReporte == 'ventas')
              _construirTablaVentas(datos, dateFormat, currencyFormat),

            pw.SizedBox(height: 30),

            // Resumen/Total
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RESUMEN',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total de $_tipoReporte:',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        _tipoReporte == 'alquileres'
                            ? '${datos['total_alquileres'] ?? 0}'
                            : '${datos['total_ventas'] ?? 0}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL INGRESOS:',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        currencyFormat.format(datos['total_ingresos'] ?? 0),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Pie de página
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Penguin Ternos - Sistema de Gestión',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _construirTablaAlquileres(
    Map<String, dynamic> datos,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    final alquileres = (datos['alquileres'] as List?) ?? [];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _celdaEncabezado('Fecha'),
            _celdaEncabezado('DNI'),
            _celdaEncabezado('Cliente'),
            _celdaEncabezado('Artículos'),
            _celdaEncabezado('Estado'),
            _celdaEncabezado('Monto'),
          ],
        ),
        // Filas de datos
        ...alquileres.map((alquiler) {
          final fecha = alquiler['created_at'] != null
              ? dateFormat.format(DateTime.parse(alquiler['created_at']))
              : 'N/A';
          final dni = alquiler['clientes']?['dni'] ?? 'N/A';
          final nombre = alquiler['clientes']?['nombre'] ?? 'N/A';
          final estado = alquiler['estado'] ?? 'N/A';
          final monto = (alquiler['monto_alquiler'] ?? 0) +
              (alquiler['garantia_retenida'] ?? 0) +
              (alquiler['mora_cobrada'] ?? 0);

          // Obtener nombres de artículos
          final articulos = (alquiler['alquiler_articulos'] as List?) ?? [];
          final nombresArticulos = articulos
              .map((a) => a['articulos']?['nombre'] ?? '')
              .where((n) => n.isNotEmpty)
              .take(2)
              .join(', ');
          final articulosTexto = nombresArticulos.isEmpty
              ? '${articulos.length} art.'
              : articulos.length > 2
                  ? '$nombresArticulos... (+${articulos.length - 2})'
                  : nombresArticulos;

          return pw.TableRow(
            children: [
              _celdaDato(fecha),
              _celdaDato(dni),
              _celdaDato(nombre),
              _celdaDato(articulosTexto),
              _celdaDato(estado.toUpperCase()),
              _celdaDato(currencyFormat.format(monto)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _construirTablaVentas(
    Map<String, dynamic> datos,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    final ventas = (datos['ventas'] as List?) ?? [];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(2.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green100),
          children: [
            _celdaEncabezado('Fecha'),
            _celdaEncabezado('DNI'),
            _celdaEncabezado('Cliente'),
            _celdaEncabezado('Artículos'),
            _celdaEncabezado('Método Pago'),
            _celdaEncabezado('Monto'),
          ],
        ),
        // Filas de datos
        ...ventas.map((venta) {
          final fecha = venta['created_at'] != null
              ? dateFormat.format(DateTime.parse(venta['created_at']))
              : 'N/A';
          final dni = venta['clientes']?['dni'] ?? 'N/A';
          final nombre = venta['clientes']?['nombre'] ?? 'N/A';
          final metodoPago =
              _getMetodoPagoTexto(venta['metodo_pago'] ?? 'efectivo');
          final monto = venta['total'] ?? 0;

          // Obtener nombres de artículos
          final articulos = (venta['venta_articulos'] as List?) ?? [];
          final nombresArticulos = articulos
              .map((a) => a['articulos']?['nombre'] ?? '')
              .where((n) => n.isNotEmpty)
              .take(2)
              .join(', ');
          final articulosTexto = nombresArticulos.isEmpty
              ? '${articulos.length} art.'
              : articulos.length > 2
                  ? '$nombresArticulos... (+${articulos.length - 2})'
                  : nombresArticulos;

          return pw.TableRow(
            children: [
              _celdaDato(fecha),
              _celdaDato(dni),
              _celdaDato(nombre),
              _celdaDato(articulosTexto),
              _celdaDato(metodoPago),
              _celdaDato(currencyFormat.format(monto)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _celdaEncabezado(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _celdaDato(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texto,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _getMetodoPagoTexto(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'yape':
        return 'Yape/Plin';
      case 'transferencia':
        return 'Transferencia';
      default:
        return metodo;
    }
  }

  Future<void> _verVistaPrevia() async {
    setState(() => _cargando = true);

    final datos = await _obtenerDatosReporte();

    setState(() {
      _cargando = false;
    });

    if (datos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al obtener datos del reporte'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vista Previa - ${_getTituloReporte()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Período: ${dateFormat.format(_fechaInicio)} - ${dateFormat.format(_fechaFin)}'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Resumen:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildResumenItem(
                'Total de $_tipoReporte',
                _tipoReporte == 'alquileres'
                    ? '${datos['total_alquileres'] ?? 0}'
                    : '${datos['total_ventas'] ?? 0}',
              ),
              _buildResumenItem(
                'Ingresos totales',
                currencyFormat.format(datos['total_ingresos'] ?? 0),
              ),
              const SizedBox(height: 16),
              if (_tipoReporte == 'alquileres' &&
                  (datos['alquileres'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Últimos 5 registros:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(datos['alquileres'] as List).take(5).map((alq) {
                      final fecha = alq['created_at'] != null
                          ? dateFormat.format(DateTime.parse(alq['created_at']))
                          : 'N/A';
                      final cliente = alq['clientes']?['nombre'] ?? 'N/A';
                      final monto = (alq['monto_alquiler'] ?? 0) +
                          (alq['garantia_retenida'] ?? 0) +
                          (alq['mora_cobrada'] ?? 0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $fecha - $cliente - ${currencyFormat.format(monto)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }),
                  ],
                )
              else if (_tipoReporte == 'ventas' &&
                  (datos['ventas'] as List).isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Últimas 5 ventas:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...(datos['ventas'] as List).take(5).map((venta) {
                      final fecha = venta['created_at'] != null
                          ? dateFormat
                              .format(DateTime.parse(venta['created_at']))
                          : 'N/A';
                      final cliente = venta['clientes']?['nombre'] ?? 'N/A';
                      final monto = venta['total'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $fecha - $cliente - ${currencyFormat.format(monto)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generarReporte();
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getTituloReporte() {
    switch (_tipoReporte) {
      case 'alquileres':
        return 'Alquileres';
      case 'ventas':
        return 'Ventas';
      case 'inventario':
        return 'Inventario';
      case 'clientes':
        return 'Clientes';
      default:
        return 'Reporte';
    }
  }
}
