import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/citas_provider.dart';
import '../../models/cita.dart';
import 'crear_cita_screen.dart';
import '../../utils/whatsapp_helper.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final provider = Provider.of<CitasProvider>(context, listen: false);
    await provider.cargarCitas();
    await provider.cargarCitasPendientes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendientes(),
          _buildHistorial(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irACrearCita,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildPendientes() {
    return Consumer<CitasProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.citasPendientes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.citasPendientes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay citas pendientes',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.citasPendientes.length,
            itemBuilder: (context, index) {
              final cita = provider.citasPendientes[index];
              return _buildCitaCard(cita);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistorial() {
    return Consumer<CitasProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.citas.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar citas completadas y canceladas, ordenar por fecha descendente
        final historial = provider.citas
            .where((c) => c.esCompletada || c.esCancelada)
            .toList()
          ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

        if (historial.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay historial de citas',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final cita = historial[index];
              return _buildCitaCard(cita);
            },
          ),
        );
      },
    );
  }

  Widget _buildCitaCard(Cita cita) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final Color estadoColor = cita.esPendiente
        ? Colors.orange
        : cita.esCompletada
            ? Colors.green
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estadoColor,
          child: Icon(
            cita.esPendiente
                ? Icons.pending
                : cita.esCompletada
                    ? Icons.check_circle
                    : Icons.cancel,
            color: Colors.white,
          ),
        ),
        title: Text(
          cita.clienteNombre ?? 'Cliente',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(cita.fechaHora)),
            Text('Tipo: ${_getTipoText(cita.tipo)}'),
            if (cita.descripcion != null && cita.descripcion!.isNotEmpty)
              Text(cita.descripcion!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: cita.esPendiente
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'completar',
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Completar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancelar',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Cancelar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'completar') {
                    _cambiarEstado(cita, 'completada');
                  } else if (value == 'cancelar') {
                    _cambiarEstado(cita, 'cancelada');
                  } else if (value == 'eliminar') {
                    _eliminarCita(cita);
                  }
                },
              )
            : null,
        onTap: () => _mostrarDetalleCita(cita),
      ),
    );
  }

  String _getTipoText(String tipo) {
    switch (tipo) {
      case 'alquiler':
        return 'Alquiler';
      case 'prueba':
        return 'Prueba de Terno';
      case 'devolucion':
        return 'Devolución';
      case 'otro':
        return 'Otro';
      default:
        return tipo;
    }
  }

  Future<void> _irACrearCita() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearCitaScreen(),
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  void _mostrarDetalleCita(Cita cita) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de Cita'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Cliente:', cita.clienteNombre ?? 'N/A'),
              _buildDetalleRow('DNI:', cita.clienteDni ?? 'N/A'),
              _buildDetalleRow('Teléfono:', cita.clienteTelefono ?? 'N/A'),
              const Divider(height: 24),
              _buildDetalleRow('Fecha:', dateFormat.format(cita.fechaHora)),
              _buildDetalleRow('Tipo:', _getTipoText(cita.tipo)),
              _buildDetalleRow(
                'Estado:',
                cita.esPendiente
                    ? 'Pendiente'
                    : cita.esCompletada
                        ? 'Completada'
                        : 'Cancelada',
              ),
              if (cita.descripcion != null && cita.descripcion!.isNotEmpty) ...[
                const Divider(height: 24),
                const Text('Descripción:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(cita.descripcion!),
              ],
            ],
          ),
        ),
        actions: [
          if (cita.esPendiente && cita.clienteTelefono != null)
            TextButton.icon(
              icon: const Icon(Icons.chat, color: Colors.green),
              label: const Text(
                'Avisar por WhatsApp',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                // Usamos la nueva función específica para citas
                WhatsappHelper.enviarRecordatorioCita(
                  context: context,
                  telefono: cita.clienteTelefono!,
                  nombreCliente: cita.clienteNombre ?? 'Cliente',
                  fechaHoraCita: dateFormat.format(cita.fechaHora),
                );
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(Cita cita, String nuevoEstado) async {
    final provider = Provider.of<CitasProvider>(context, listen: false);
    final resultado = await provider.actualizarEstado(cita.id!, nuevoEstado);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado
              ? 'Cita actualizada exitosamente'
              : 'Error al actualizar cita'),
          backgroundColor: resultado ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarCita(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de eliminar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final provider = Provider.of<CitasProvider>(context, listen: false);
      final resultado = await provider.eliminarCita(cita.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado
                ? 'Cita eliminada exitosamente'
                : 'Error al eliminar cita'),
            backgroundColor: resultado ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
