import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alquileres_provider.dart';
import '../../models/alquiler.dart';
import 'crear_alquiler_screen.dart';
import 'detalle_alquiler_screen.dart';
import 'package:intl/intl.dart';
import '../../utils/whatsapp_helper.dart';

class AlquileresScreen extends StatefulWidget {
  const AlquileresScreen({super.key});

  @override
  State<AlquileresScreen> createState() => _AlquileresScreenState();
}

class _AlquileresScreenState extends State<AlquileresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final provider = Provider.of<AlquileresProvider>(context, listen: false);
    await provider.cargarActivos();
    await provider.cargarHistorial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alquileres'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActivos(),
            _buildHistorial(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearAlquilerScreen()),
          );
          if (result == true) {
            _cargarDatos();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Alquiler'),
        backgroundColor: Colors.lightBlue,
      ),
    );
  }

  Widget _buildActivos() {
    return Consumer<AlquileresProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.alquileresActivos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay alquileres activos',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.alquileresActivos.length,
          itemBuilder: (context, index) {
            final alquiler = provider.alquileresActivos[index];
            return _buildAlquilerCard(alquiler, true);
          },
        );
      },
    );
  }

  Widget _buildHistorial() {
    return Consumer<AlquileresProvider>(
      builder: (context, provider, child) {
        if (provider.historial.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay historial de alquileres',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.historial.length,
          itemBuilder: (context, index) {
            final alquiler = provider.historial[index];
            return _buildAlquilerCard(alquiler, false);
          },
        );
      },
    );
  }

  Widget _buildAlquilerCard(Alquiler alquiler, bool isActivo) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final hasMora = alquiler.isMoraVencida;
    final diasMora = alquiler.diasMora;

    // Usamos el getter que agregamos al modelo (asegúrate de tenerlo en alquiler.dart)
    // Si da error, temporalmente usa: bool porVencer = false;
    final porVencer = alquiler.estaPorVencer;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      // Si está por vencer, le damos un borde naranja suave
      shape: porVencer && isActivo
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.orange, width: 2),
              borderRadius: BorderRadius.circular(12))
          : null,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    DetalleAlquilerScreen(alquilerId: alquiler.id!)),
          );
          if (result == true) {
            _cargarDatos();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Cabecera (Nombre y Mora) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alquiler.cliente?.nombre ?? 'Cliente',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'DNI: ${alquiler.cliente?.dni ?? ""}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (hasMora && isActivo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$diasMora días mora',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),

              // --- Fechas ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha inicio',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(dateFormat.format(alquiler.fechaInicio),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Fecha fin',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(dateFormat.format(alquiler.fechaFin),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              // --- NUEVO: Botón de Alerta de Vencimiento ---
              if (porVencer && isActivo) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      WhatsappHelper.enviarRecordatorio(
                        context: context,
                        telefono: alquiler.cliente?.telefono ?? '',
                        nombreCliente: alquiler.cliente?.nombre ?? '',
                        fechaVencimiento: dateFormat.format(alquiler.fechaFin),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text("Vence pronto: Enviar aviso"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade900,
                      elevation: 0,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // --- Pie de tarjeta (Artículos y precio) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${alquiler.articulos.length} artículo(s)',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    currencyFormat.format(alquiler.montoAlquiler),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
