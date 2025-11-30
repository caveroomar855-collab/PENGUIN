import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ventas_provider.dart';
import '../../models/venta.dart';
import 'package:intl/intl.dart';
import 'crear_venta_screen.dart';

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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearVentaScreen()),
          ).then((_) => _cargarDatos());
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
        onTap: () => _mostrarDetalleVenta(venta),
      ),
    );
  }

  void _mostrarDetalleVenta(Venta venta) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de Venta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información del cliente
              _buildDetalleSeccion('CLIENTE'),
              _buildDetalleRow('Nombre:', venta.cliente?.nombre ?? 'N/A'),
              _buildDetalleRow('DNI:', venta.cliente?.dni ?? 'N/A'),
              _buildDetalleRow('Teléfono:', venta.cliente?.telefono ?? 'N/A'),

              const Divider(height: 24),

              // Información de la venta
              _buildDetalleSeccion('VENTA'),
              if (venta.createdAt != null)
                _buildDetalleRow('Fecha:', dateFormat.format(venta.createdAt!)),
              _buildDetalleRow(
                'Método de Pago:',
                _getMetodoPagoTexto(venta.metodoPago),
              ),
              _buildDetalleRow(
                'Estado:',
                venta.isDevuelta ? 'Devuelta' : 'Completada',
                color: venta.isDevuelta ? Colors.orange : Colors.green,
              ),
              if (venta.fechaDevolucion != null)
                _buildDetalleRow(
                  'Fecha Devolución:',
                  dateFormat.format(venta.fechaDevolucion!),
                ),

              const Divider(height: 24),

              // Artículos
              _buildDetalleSeccion('ARTÍCULOS'),
              const SizedBox(height: 8),
              ...venta.articulos.map((art) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shopping_bag,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                art.articulo?.nombre ?? 'Artículo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              if (art.articulo != null)
                                /*Text(
                                  art.articulo!.tipo.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),*/

                                Text(
                                  // Agregamos la lógica para mostrar la talla si existe
                                  '${art.articulo!.tipo.toUpperCase()}${art.articulo!.talla != null && art.articulo!.talla!.isNotEmpty ? " - Talla: ${art.articulo!.talla}" : ""}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(art.precio),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),

              const Divider(height: 24),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currencyFormat.format(venta.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (venta.puedeDevolver)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmarDevolucion(venta);
              },
              child: const Text('Procesar Devolución'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
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

  Future<void> _confirmarDevolucion(Venta venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Devolución'),
        content: const Text(
          '¿Está seguro de procesar la devolución de esta venta?\n\n'
          'Los artículos volverán al inventario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar Devolución'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final provider = Provider.of<VentasProvider>(context, listen: false);
      final resultado = await provider.procesarDevolucion(venta.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['success'] == true
                ? 'Devolución procesada exitosamente'
                : 'Error al procesar devolución: ${resultado['error'] ?? 'Desconocido'}'),
            backgroundColor:
                resultado['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
