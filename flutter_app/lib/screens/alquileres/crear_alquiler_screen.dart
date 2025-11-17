import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alquileres_provider.dart';
import '../../providers/clientes_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/cliente.dart';
import 'package:intl/intl.dart';

class CrearAlquilerScreen extends StatefulWidget {
  const CrearAlquilerScreen({super.key});

  @override
  State<CrearAlquilerScreen> createState() => _CrearAlquilerScreenState();
}

class _CrearAlquilerScreenState extends State<CrearAlquilerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _montoController = TextEditingController();
  final _garantiaController = TextEditingController();

  Cliente? _clienteSeleccionado;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 3));
  final List<String> _articulosSeleccionados = [];
  final List<String> _trajesSeleccionados = [];

  bool _isLoading = false;
  bool _buscandoCliente = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _garantiaController.text = '50.00';
  }

  Future<void> _cargarDatos() async {
    final clientesProvider =
        Provider.of<ClientesProvider>(context, listen: false);
    final inventarioProvider =
        Provider.of<InventarioProvider>(context, listen: false);

    await Future.wait([
      clientesProvider.cargarClientes(),
      inventarioProvider.cargarArticulos(),
      inventarioProvider.cargarTrajes(),
    ]);
  }

  Future<void> _buscarClientePorDni() async {
    if (_dniController.text.isEmpty) return;

    setState(() => _buscandoCliente = true);

    final clientesProvider =
        Provider.of<ClientesProvider>(context, listen: false);
    final cliente = clientesProvider.clientes.firstWhere(
      (c) => c.dni == _dniController.text && !c.enPapelera,
      orElse: () => Cliente(nombre: '', dni: '', telefono: ''),
    );

    setState(() {
      _clienteSeleccionado = cliente.id != null ? cliente : null;
      _buscandoCliente = false;
    });

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente no encontrado')),
      );
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe buscar y seleccionar un cliente')),
      );
      return;
    }
    if (_articulosSeleccionados.isEmpty && _trajesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debe seleccionar al menos un artículo o traje')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<AlquileresProvider>(context, listen: false);
    final success = await provider.crearAlquiler(
      clienteId: _clienteSeleccionado!.id!,
      articulosIds:
          _articulosSeleccionados.map((id) => int.tryParse(id) ?? 0).toList(),
      trajesIds:
          _trajesSeleccionados.map((id) => int.tryParse(id) ?? 0).toList(),
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      montoAlquiler: double.parse(_montoController.text),
      garantia: double.parse(_garantiaController.text),
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alquiler creado exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el alquiler')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Alquiler'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSeccionCliente(),
                  const SizedBox(height: 24),
                  _buildSeccionFechas(),
                  const SizedBox(height: 24),
                  _buildSeccionArticulos(),
                  const SizedBox(height: 24),
                  _buildSeccionTrajes(),
                  const SizedBox(height: 24),
                  _buildSeccionMontos(),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Alquiler'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dniController,
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    validator: (v) => v == null || v.length != 8
                        ? 'Ingrese DNI válido'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _buscandoCliente ? null : _buscarClientePorDni,
                  icon: _buscandoCliente
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            if (_clienteSeleccionado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _clienteSeleccionado!.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Tel: ${_clienteSeleccionado!.telefono}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionFechas() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fechas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaInicio,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _fechaInicio = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha Inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFormat.format(_fechaInicio)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaFin,
                        firstDate: _fechaInicio,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _fechaFin = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha Fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
                      ),
                      child: Text(dateFormat.format(_fechaFin)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionArticulos() {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        final disponibles =
            provider.articulos.where((a) => a.estado == 'disponible').toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Artículos Sueltos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (disponibles.isEmpty)
                  const Text('No hay artículos disponibles',
                      style: TextStyle(color: Colors.grey))
                else
                  ...disponibles.map((articulo) {
                    final isSelected =
                        _articulosSeleccionados.contains(articulo.id);
                    return CheckboxListTile(
                      title: Text('${articulo.tipo} - ${articulo.talla}'),
                      subtitle: Text('${articulo.color} - ${articulo.codigo}'),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _articulosSeleccionados.add(articulo.id!);
                          } else {
                            _articulosSeleccionados.remove(articulo.id);
                          }
                        });
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeccionTrajes() {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        final disponibles = provider.trajes
            .where((t) => t.articulos.every((a) => a.estado == 'disponible'))
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trajes Completos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (disponibles.isEmpty)
                  const Text('No hay trajes disponibles',
                      style: TextStyle(color: Colors.grey))
                else
                  ...disponibles.map((traje) {
                    final isSelected = _trajesSeleccionados.contains(traje.id);
                    return CheckboxListTile(
                      title: Text(traje.nombre),
                      subtitle: Text('${traje.articulos.length} piezas'),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _trajesSeleccionados.add(traje.id!);
                          } else {
                            _trajesSeleccionados.remove(traje.id);
                          }
                        });
                      },
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeccionMontos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Montos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto del Alquiler (S/)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingrese el monto';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Monto inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _garantiaController,
              decoration: const InputDecoration(
                labelText: 'Garantía (S/)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingrese la garantía';
                if (double.tryParse(v) == null || double.parse(v) < 0) {
                  return 'Garantía inválida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _montoController.dispose();
    _garantiaController.dispose();
    super.dispose();
  }
}
