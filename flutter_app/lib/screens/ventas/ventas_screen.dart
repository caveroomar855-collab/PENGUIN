import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ventas_provider.dart';
import '../../models/venta.dart';
import 'package:intl/intl.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final provider = Provider.of<VentasProvider>(context, listen: false);
    await provider.cargarVentas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: Consumer<VentasProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.ventas.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay ventas registradas',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.ventas.length,
              itemBuilder: (context, index) {
                final venta = provider.ventas[index];
                return _buildVentaCard(venta);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogoNuevaVenta();
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva Venta'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildVentaCard(Venta venta) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final puedeDevolver = venta.puedeDevolver;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: puedeDevolver ? Colors.green : Colors.grey,
          child: const Icon(Icons.shopping_bag, color: Colors.white),
        ),
        title: Text(venta.cliente?.nombre ?? 'Cliente',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${venta.articulos.length} artículo(s)'),
            if (venta.createdAt != null)
              Text(dateFormat.format(venta.createdAt!)),
            if (puedeDevolver)
              const Text('Puede devolver',
                  style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        trailing: Text(
          currencyFormat.format(venta.total),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        onTap: () {
          _mostrarDetalleVenta(venta);
        },
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaVenta() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de ventas en desarrollo')),
    );
  }

  Future<void> _mostrarDetalleVenta(Venta venta) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detalle de venta en desarrollo')),
    );
  }
}
