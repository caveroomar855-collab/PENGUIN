import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/clientes_provider.dart';
import '../../models/cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Navegar a papelera
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Papelera - En desarrollo')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente por DNI o nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<ClientesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientes = provider.clientes.where((cliente) {
                  return cliente.dni.toLowerCase().contains(_searchQuery) ||
                      cliente.nombre.toLowerCase().contains(_searchQuery);
                }).toList();

                if (clientes.isEmpty) {
                  return const Center(
                    child: Text('No hay clientes registrados'),
                  );
                }

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return _buildClienteCard(cliente);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Crear cliente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear cliente - En desarrollo')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(cliente.nombre[0].toUpperCase()),
        ),
        title: Text(
          cliente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DNI: ${cliente.dni}'),
            Text('Tel: ${cliente.telefono}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Mostrar opciones
          },
        ),
        onTap: () {
          // TODO: Ver detalles
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
