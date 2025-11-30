import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventarioProvider>(context);
    final historial = provider.historial;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpiar historial'),
                  content: const Text('¿Eliminar todo el historial?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await provider.clearHistorial();
              }
            },
          )
        ],
      ),
      body: historial.isEmpty
          ? const Center(child: Text('No hay eventos en el historial'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: historial.length,
              itemBuilder: (context, index) {
                final e = historial[index];
                final ts =
                    DateTime.tryParse(e['timestamp'] ?? '') ?? DateTime.now();
                final tipo = e['tipo'] ?? '';
                final mensaje = e['mensaje'] ?? '';
                final data = e['data'] ?? {};

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colorForTipo(tipo),
                      child: Icon(_iconForTipo(tipo), color: Colors.white),
                    ),
                    title: Text(mensaje),
                    subtitle: Text(
                        '${dateFormat.format(ts)} • ${_dataPreview(data)}'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(mensaje),
                          content: SingleChildScrollView(
                            child: Text(e.toString()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _dataPreview(dynamic data) {
    try {
      if (data == null) return '';
      if (data is Map && data.isNotEmpty) {
        final entries =
            (data).entries.take(3).map((e) => '${e.key}: ${e.value}');
        return entries.join(' • ');
      }
      return data.toString();
    } catch (_) {
      return '';
    }
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'create':
        return Colors.green;
      case 'delete':
        return Colors.red;
      case 'mantenimiento':
        return Colors.orange;
      case 'estado':
        return Colors.blue;
      case 'sync':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'create':
        return Icons.add;
      case 'delete':
        return Icons.delete;
      case 'mantenimiento':
        return Icons.build;
      case 'estado':
        return Icons.swap_horiz;
      case 'sync':
        return Icons.sync;
      default:
        return Icons.history;
    }
  }
}
