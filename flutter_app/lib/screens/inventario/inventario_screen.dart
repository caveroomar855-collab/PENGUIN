import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/articulo.dart';
import '../../models/traje.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final provider = Provider.of<InventarioProvider>(context, listen: false);
    await provider.cargarArticulos();
    await provider.cargarTrajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Artículos'),
            Tab(text: 'Trajes'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArticulos(),
                _buildTrajes(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agregar artículo en desarrollo')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildArticulos() {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        final articulos = provider.articulos.where((a) {
          final search = _searchQuery;
          if (search.isEmpty) return true;
          return a.codigo.toLowerCase().contains(search) ||
              a.tipo.toLowerCase().contains(search) ||
              (a.color?.toLowerCase().contains(search) ?? false);
        }).toList();

        if (articulos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay artículos',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: articulos.length,
          itemBuilder: (context, index) {
            final articulo = articulos[index];
            return _buildArticuloCard(articulo);
          },
        );
      },
    );
  }

  Widget _buildTrajes() {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        final trajes = provider.trajes.where((t) {
          final search = _searchQuery;
          if (search.isEmpty) return true;
          return t.nombre.toLowerCase().contains(search);
        }).toList();

        if (trajes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checkroom, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay trajes',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: trajes.length,
          itemBuilder: (context, index) {
            final traje = trajes[index];
            return _buildTrajeCard(traje);
          },
        );
      },
    );
  }

  Widget _buildArticuloCard(Articulo articulo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEstadoColor(articulo.estado),
          child: const Icon(Icons.checkroom, color: Colors.white),
        ),
        title: Text('${articulo.tipo} - ${articulo.talla}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${articulo.color} - ${articulo.codigo}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getEstadoColor(articulo.estado),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                articulo.estado.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
        onTap: () {
          _mostrarDetalleArticulo(articulo);
        },
      ),
    );
  }

  Widget _buildTrajeCard(Traje traje) {
    final todosDisponibles =
        traje.articulos.every((a) => a.estado == 'disponible');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: todosDisponibles ? Colors.green : Colors.grey,
          child: const Icon(Icons.checkroom, color: Colors.white),
        ),
        title: Text(traje.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${traje.articulos.length} piezas'),
        children: traje.articulos.map((articulo) {
          return ListTile(
            dense: true,
            leading: Icon(Icons.circle,
                size: 10, color: _getEstadoColor(articulo.estado)),
            title: Text('${articulo.tipo} - ${articulo.color}'),
            subtitle: Text(articulo.codigo),
            trailing: Text(articulo.estado,
                style: TextStyle(
                    fontSize: 11, color: _getEstadoColor(articulo.estado))),
          );
        }).toList(),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'disponible':
        return Colors.green;
      case 'alquilado':
        return Colors.blue;
      case 'mantenimiento':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _mostrarDetalleArticulo(Articulo articulo) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(articulo.tipo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${articulo.codigo}'),
            Text('Talla: ${articulo.talla ?? "N/A"}'),
            Text('Color: ${articulo.color ?? "N/A"}'),
            const SizedBox(height: 8),
            Text('Estado: ${articulo.estado}',
                style: TextStyle(
                    color: _getEstadoColor(articulo.estado),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
