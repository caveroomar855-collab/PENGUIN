import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/alquileres_provider.dart';
import '../../providers/config_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../alquileres/alquileres_screen.dart';
import '../ventas/ventas_screen.dart';
import '../inventario/inventario_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  Map<String, dynamic>? _resumenDia;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarResumenDia();
  }

  Future<void> _cargarResumenDia() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.reportes}/resumen-dia'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _resumenDia = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando resumen: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context).configuracion;
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarResumenDia,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarResumenDia,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saludo
                    Text(
                      '¡Hola, ${config?.nombreEmpleado ?? "Empleado"}!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'es')
                          .format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Botones principales
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildMenuCard(
                          context,
                          'Alquileres',
                          Icons.event_available,
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AlquileresScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Ventas',
                          Icons.shopping_cart,
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const VentasScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Inventario',
                          Icons.inventory_2,
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const InventarioScreen()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          'Citas',
                          Icons.calendar_today,
                          Colors.purple,
                          () {
                            // TODO: Implementar pantalla de citas
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Función en desarrollo')),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Resumen del día
                    Text(
                      'Resumen del día',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    if (_resumenDia != null) ...[
                      _buildResumenCard(
                        'Alquileres Activos',
                        _resumenDia!['alquileres_activos']?.toString() ?? '0',
                        Icons.event_available,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildResumenCard(
                        'Citas Pendientes',
                        _resumenDia!['citas_pendientes']?.toString() ?? '0',
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                      const SizedBox(height: 24),

                      // Ganancias
                      Text(
                        'Ganancias del día',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildGananciaRow(
                                'Alquileres',
                                currencyFormat.format(
                                    _resumenDia!['ganancias_alquileres'] ?? 0),
                                Colors.blue,
                              ),
                              const Divider(height: 24),
                              _buildGananciaRow(
                                'Ventas',
                                currencyFormat.format(
                                    _resumenDia!['ganancias_ventas'] ?? 0),
                                Colors.green,
                              ),
                              const Divider(height: 24),
                              _buildGananciaRow(
                                'Total',
                                currencyFormat.format(
                                    _resumenDia!['ganancia_total'] ?? 0),
                                Colors.orange,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGananciaRow(String label, String amount, Color color,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
