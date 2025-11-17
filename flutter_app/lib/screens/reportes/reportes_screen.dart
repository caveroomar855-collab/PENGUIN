import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  String _tipoReporte = 'alquileres';

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
            onPressed: _generarReporte,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generar Reporte PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _verVistaPrevia,
            icon: const Icon(Icons.visibility),
            label: const Text('Ver Vista Previa'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando PDF... (Función en desarrollo)'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implementar generación de PDF con package 'pdf'
  }

  Future<void> _verVistaPrevia() async {
    final dateFormat = DateFormat('dd/MM/yyyy');

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
              _buildResumenItem('Total de operaciones', '0'),
              _buildResumenItem('Ingresos totales', 'S/ 0.00'),
              _buildResumenItem('Garantías retenidas', 'S/ 0.00'),
              _buildResumenItem('Moras cobradas', 'S/ 0.00'),
              const SizedBox(height: 16),
              const Text(
                'Conecte el backend para ver datos reales',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generarReporte();
            },
            child: const Text('Generar PDF'),
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
