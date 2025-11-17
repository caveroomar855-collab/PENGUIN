import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alquileres_provider.dart';
import '../../models/alquiler.dart';
import 'package:intl/intl.dart';

class DetalleAlquilerScreen extends StatefulWidget {
  final String alquilerId;

  const DetalleAlquilerScreen({super.key, required this.alquilerId});

  @override
  State<DetalleAlquilerScreen> createState() => _DetalleAlquilerScreenState();
}

class _DetalleAlquilerScreenState extends State<DetalleAlquilerScreen> {
  Alquiler? _alquiler;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _isLoading = true);

    final provider = Provider.of<AlquileresProvider>(context, listen: false);
    final alquiler = await provider.obtenerPorId(widget.alquilerId);

    if (mounted) {
      setState(() {
        _alquiler = alquiler;
        _isLoading = false;
      });
    }
  }

  Future<void> _mostrarDialogoDevolucion() async {
    if (_alquiler == null) return;

    String? estadoSeleccionado = 'completo';
    bool retenerGarantia = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marcar Devolución'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿En qué estado se devolvieron los artículos?'),
              const SizedBox(height: 12),
              RadioListTile<String>(
                title: const Text('Completo (sin daños)'),
                value: 'completo',
                groupValue: estadoSeleccionado,
                onChanged: (val) =>
                    setDialogState(() => estadoSeleccionado = val),
              ),
              RadioListTile<String>(
                title: const Text('Con daños'),
                value: 'danado',
                groupValue: estadoSeleccionado,
                onChanged: (val) =>
                    setDialogState(() => estadoSeleccionado = val),
              ),
              RadioListTile<String>(
                title: const Text('Perdido'),
                value: 'perdido',
                groupValue: estadoSeleccionado,
                onChanged: (val) =>
                    setDialogState(() => estadoSeleccionado = val),
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text('Retener garantía'),
                subtitle: Text('S/ ${_alquiler!.garantia.toStringAsFixed(2)}'),
                value: retenerGarantia,
                onChanged: (val) =>
                    setDialogState(() => retenerGarantia = val ?? false),
              ),
              if (_alquiler!.isMoraVencida) ...[
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Mora de ${_alquiler!.diasMora} días',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final provider = Provider.of<AlquileresProvider>(context, listen: false);
      final articulos = _alquiler!.articulos
          .map((a) => {
                'articulo_id': a.articuloId,
                'estado': estadoSeleccionado,
              })
          .toList();

      final success = await provider.marcarDevolucion(
        widget.alquilerId,
        articulos,
        retenerGarantia,
        retenerGarantia ? 'Garantía retenida' : null,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Devolución registrada exitosamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al registrar la devolución')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del Alquiler')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_alquiler == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del Alquiler')),
        body: const Center(child: Text('No se pudo cargar el alquiler')),
      );
    }

    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final esActivo = _alquiler!.fechaDevolucion == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Alquiler'),
        actions: esActivo
            ? [
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'devolucion',
                      child: Row(
                        children: [
                          Icon(Icons.assignment_return),
                          SizedBox(width: 8),
                          Text('Marcar Devolución'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'devolucion') {
                      _mostrarDialogoDevolucion();
                    }
                  },
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeccionCliente(),
            const SizedBox(height: 16),
            _buildSeccionFechas(dateFormat),
            const SizedBox(height: 16),
            _buildSeccionArticulos(),
            const SizedBox(height: 16),
            _buildSeccionMontos(currencyFormat),
            if (_alquiler!.isMoraVencida && esActivo) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        'Mora de ${_alquiler!.diasMora} días',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionCliente() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_alquiler!.cliente?.nombre ?? 'N/A'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DNI: ${_alquiler!.cliente?.dni ?? "N/A"}'),
                  Text('Tel: ${_alquiler!.cliente?.telefono ?? "N/A"}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFechas(DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fechas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow(
                'Fecha Inicio',
                dateFormat.format(_alquiler!.fechaInicio),
                Icons.calendar_today),
            _buildInfoRow('Fecha Fin', dateFormat.format(_alquiler!.fechaFin),
                Icons.event),
            if (_alquiler!.fechaDevolucion != null)
              _buildInfoRow(
                  'Fecha Devolución',
                  dateFormat.format(_alquiler!.fechaDevolucion!),
                  Icons.assignment_return),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionArticulos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Artículos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (_alquiler!.articulos.isEmpty)
              const Text('No hay artículos',
                  style: TextStyle(color: Colors.grey))
            else
              ..._alquiler!.articulos.map((articuloData) {
                final articulo = articuloData.articulo;
                if (articulo == null) return const SizedBox();

                return ListTile(
                  leading: const Icon(Icons.checkroom),
                  title: Text('${articulo.tipo} - ${articulo.talla}'),
                  subtitle: Text('${articulo.color} - ${articulo.codigo}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(articuloData.estado),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      articuloData.estado.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionMontos(NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Montos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildInfoRow(
                'Monto Alquiler',
                currencyFormat.format(_alquiler!.montoAlquiler),
                Icons.attach_money),
            _buildInfoRow('Garantía',
                currencyFormat.format(_alquiler!.garantia), Icons.security),
            if (_alquiler!.garantiaRetenida > 0)
              _buildInfoRow(
                  'Garantía Retenida', 'Sí', Icons.warning, Colors.red),
            if (_alquiler!.moraCobrada > 0)
              _buildInfoRow(
                  'Mora Cobrada',
                  currencyFormat.format(_alquiler!.moraCobrada),
                  Icons.error,
                  Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
}
