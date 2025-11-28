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
    // Nuevo diálogo: tres secciones (Completo, Con daños, Perdido)
    // Agrupar unidades por articulo_id
    // Count only units that are still 'alquilado' (available to return)
    final Map<String, int> available = {};
    final Map<String, dynamic> articuloDataById = {};
    for (final a in _alquiler!.articulos) {
      final id = a.articuloId;
      if (a.estado.toLowerCase() == 'alquilado') {
        available[id] = (available[id] ?? 0) + 1;
      }
      if (articuloDataById[id] == null) articuloDataById[id] = a.articulo;
    }

    bool retenerGarantia = false;
    final Map<String, int> selCompleto = {};
    final Map<String, int> selDanado = {};
    final Map<String, int> selPerdido = {};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        int totalSelected(String id) {
          return (selCompleto[id] ?? 0) +
              (selDanado[id] ?? 0) +
              (selPerdido[id] ?? 0);
        }

        Widget buildArticleRow(String artId, String state) {
          final art = articuloDataById[artId];
          final max = available[artId] ?? 1;
          final otherSelected = totalSelected(artId) -
              (state == 'completo'
                  ? (selCompleto[artId] ?? 0)
                  : state == 'danado'
                      ? (selDanado[artId] ?? 0)
                      : (selPerdido[artId] ?? 0));
          final remaining = max - otherSelected;
          final cur = (state == 'completo'
                  ? selCompleto[artId]
                  : state == 'danado'
                      ? selDanado[artId]
                      : selPerdido[artId]) ??
              0;

          final disabled = remaining <= 0 && cur == 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${art?.tipo ?? ''} - ${art?.talla ?? ''} - ${art?.nombre ?? ''}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: disabled ? Colors.grey : null)),
                        const SizedBox(height: 4),
                        Text('Disponibles: $max',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: disabled ? Colors.grey.shade200 : null,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: disabled || cur <= 0
                              ? null
                              : () {
                                  setDialogState(() {
                                    if (state == 'completo') {
                                      selCompleto[artId] =
                                          (selCompleto[artId] ?? 0) - 1;
                                      if (selCompleto[artId]! <= 0) {
                                        selCompleto.remove(artId);
                                      }
                                    } else if (state == 'danado') {
                                      selDanado[artId] =
                                          (selDanado[artId] ?? 0) - 1;
                                      if (selDanado[artId]! <= 0) {
                                        selDanado.remove(artId);
                                      }
                                    } else {
                                      selPerdido[artId] =
                                          (selPerdido[artId] ?? 0) - 1;
                                      if (selPerdido[artId]! <= 0) {
                                        selPerdido.remove(artId);
                                      }
                                    }
                                  });
                                },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('$cur',
                              style: TextStyle(
                                  color: disabled ? Colors.grey : null)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: disabled || cur >= remaining
                              ? null
                              : () {
                                  setDialogState(() {
                                    if (state == 'completo') {
                                      selCompleto[artId] =
                                          (selCompleto[artId] ?? 0) + 1;
                                    } else if (state == 'danado') {
                                      selDanado[artId] =
                                          (selDanado[artId] ?? 0) + 1;
                                    } else {
                                      selPerdido[artId] =
                                          (selPerdido[artId] ?? 0) + 1;
                                    }
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AlertDialog(
          title: const Text('Marcar Devolución'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seleccione estado y cantidad por artículo:'),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('COMPLETO'),
                  initiallyExpanded: true,
                  children: [
                    for (final artId in available.keys)
                      // Skip rows with zero available units (already fully returned)
                      if ((available[artId] ?? 0) > 0) buildArticleRow(artId, 'completo')
                  ],
                ),
                ExpansionTile(
                  title: const Text('CON DAÑOS'),
                  children: [
                    for (final artId in available.keys)
                      if ((available[artId] ?? 0) > 0) buildArticleRow(artId, 'danado')
                  ],
                ),
                ExpansionTile(
                  title: const Text('PERDIDO'),
                  children: [
                    for (final artId in available.keys)
                      if ((available[artId] ?? 0) > 0) buildArticleRow(artId, 'perdido')
                  ],
                ),
                const Divider(),
                CheckboxListTile(
                  title: const Text('Retener garantía'),
                  subtitle:
                      Text('S/ ${_alquiler!.garantia.toStringAsFixed(2)}'),
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
                        Text('Mora de ${_alquiler!.diasMora} días',
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              child: const Text('Confirmar'),
            ),
          ],
        );
      }),
    );

    if (result == true && mounted) {
      final provider = Provider.of<AlquileresProvider>(context, listen: false);

      final List<Map<String, dynamic>> articulosPayload = [];
      selCompleto.forEach((k, v) {
        if (v > 0) {
          articulosPayload.add({
            'articulo_id': k,
            'estado_devolucion': 'completo',
            'cantidad': v
          });
        }
      });
      selDanado.forEach((k, v) {
        if (v > 0) {
          articulosPayload.add(
              {'articulo_id': k, 'estado_devolucion': 'danado', 'cantidad': v});
        }
      });
      selPerdido.forEach((k, v) {
        if (v > 0) {
          articulosPayload.add({
            'articulo_id': k,
            'estado_devolucion': 'perdido',
            'cantidad': v
          });
        }
      });

      // Mostrar resumen y pedir confirmación antes de enviar
      final resumenLines = <String>[];
      if (selCompleto.isNotEmpty) {
        resumenLines.add('COMPLETO:');
        selCompleto.forEach((k, v) {
          final art = articuloDataById[k];
          resumenLines.add('  ${art?.tipo ?? ''} ${art?.nombre ?? ''} x$v');
        });
      }
      if (selDanado.isNotEmpty) {
        resumenLines.add('CON DAÑOS:');
        selDanado.forEach((k, v) {
          final art = articuloDataById[k];
          resumenLines.add('  ${art?.tipo ?? ''} ${art?.nombre ?? ''} x$v');
        });
      }
      if (selPerdido.isNotEmpty) {
        resumenLines.add('PERDIDO:');
        selPerdido.forEach((k, v) {
          final art = articuloDataById[k];
          resumenLines.add('  ${art?.tipo ?? ''} ${art?.nombre ?? ''} x$v');
        });
      }

      // If only one unit is being returned, show a minimal confirmation dialog
      final totalSelected = articulosPayload.fold<int>(0, (s, e) => s + (e['cantidad'] as int? ?? 1));
      bool? confirmar;
      if (totalSelected == 1) {
        confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Devolución'),
            content: Text(resumenLines.isNotEmpty ? resumenLines.join('\n') : 'Devolver 1 artículo?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar')),
            ],
          ),
        );
      } else {
        confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Devolución'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...resumenLines.map((l) => Text(l)),
                  const SizedBox(height: 12),
                  if (retenerGarantia)
                    Text('Se retendrá la garantía', style: TextStyle(color: Colors.orange[800])),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
            ],
          ),
        );
      }

      if (confirmar != true) return;

      final success = await provider.marcarDevolucion(
        widget.alquilerId,
        articulosPayload,
        retenerGarantia,
        retenerGarantia ? 'Garantía retenida' : null,
      );

      if (mounted) {
        if (success) {
          // Refresh the detalle screen to show updated item states (greyed returned items)
          await _cargarDetalle();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Devolución registrada exitosamente')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error al registrar la devolución')));
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
                  title: Text(
                      '${articulo.tipo} - ${articulo.talla} - ${articulo.nombre}'),
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
              }),
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
