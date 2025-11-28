import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/alquileres_provider.dart';
import '../../providers/clientes_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/cliente.dart';
import '../../models/articulo.dart';
import '../../models/traje.dart';
import 'package:intl/intl.dart';
import '../../utils/validators.dart';

class CrearAlquilerScreen extends StatefulWidget {
  const CrearAlquilerScreen({super.key});

  @override
  State<CrearAlquilerScreen> createState() => _CrearAlquilerScreenState();
}

class _CrearAlquilerScreenState extends State<CrearAlquilerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _garantiaController = TextEditingController();

  Cliente? _clienteExistente;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 3));
  final List<Map<String, dynamic>> _articulosSeleccionados = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('CrearAlquilerScreen.initState');
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
    if (!mounted) return;
  }

  double get _totalAlquiler {
    return _articulosSeleccionados.fold<double>(
      0,
      (sum, entry) {
        final art = entry['articulo'] as Articulo;
        final qty = entry['cantidad'] as int;
        return sum + art.precioAlquiler * qty;
      },
    );
  }

  int get _diasAlquiler {
    return _fechaFin.difference(_fechaInicio).inDays + 1;
  }

  Future<void> _buscarClientePorDni() async {
    if (_dniController.text.isEmpty) return;

    final clientesProvider =
        Provider.of<ClientesProvider>(context, listen: false);
    final cliente = clientesProvider.clientes.firstWhere(
      (c) => c.dni == _dniController.text && !c.enPapelera,
      orElse: () => Cliente(nombre: '', dni: '', telefono: ''),
    );

    setState(() {
      if (cliente.id != null) {
        _clienteExistente = cliente;
        _nombreController.text = cliente.nombre;
        _telefonoController.text = cliente.telefono;
      } else {
        _clienteExistente = null;
        _nombreController.clear();
        _telefonoController.clear();
      }
    });
  }

  Future<void> _seleccionarArticulos() async {
    final inventarioProvider =
        Provider.of<InventarioProvider>(context, listen: false);
    debugPrint('CrearAlquilerScreen._seleccionarArticulos: start');
    final articulosDisponibles = inventarioProvider.articulos
        .where((a) => a.cantidadDisponible > 0)
        .toList();

    if (articulosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay artículos disponibles')),
      );
      return;
    }

    final seleccionados = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => _DialogoSeleccionArticulos(
        articulos: articulosDisponibles,
        articulosYaSeleccionados: _articulosSeleccionados,
        esAlquiler: true,
      ),
    );
    debugPrint(
        'CrearAlquilerScreen._seleccionarArticulos: dialog closed, result=${seleccionados?.length}');
    if (!mounted) return;

    if (seleccionados != null) {
      setState(() {
        _articulosSeleccionados.clear();
        _articulosSeleccionados.addAll(seleccionados);
      });
    }
  }

  Future<void> _seleccionarTraje() async {
    final inventarioProvider =
        Provider.of<InventarioProvider>(context, listen: false);

    if (inventarioProvider.trajes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay trajes disponibles')),
      );
      return;
    }

    final traje = await showDialog<Traje>(
      context: context,
      builder: (context) => _DialogoSeleccionTraje(
        trajes: inventarioProvider.trajes,
      ),
    );

    if (!mounted) return;

    if (traje != null && traje.articulos.isNotEmpty) {
      final articulosDisponibles =
          traje.articulos.where((a) => a.cantidadDisponible > 0).toList();

      if (articulosDisponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Este traje no tiene artículos disponibles')),
        );
        return;
      }

      final seleccionados = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (context) => _DialogoSeleccionArticulos(
          articulos: articulosDisponibles,
          articulosYaSeleccionados: _articulosSeleccionados,
          tituloPersonalizado: 'Seleccionar piezas de ${traje.nombre}',
          esAlquiler: true,
        ),
      );
      if (!mounted) return;

      if (seleccionados != null) {
        setState(() {
          _articulosSeleccionados.clear();
          _articulosSeleccionados.addAll(seleccionados);
        });
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_articulosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un artículo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Si no existe el cliente, crearlo primero
    String clienteId;
    if (_clienteExistente != null) {
      clienteId = _clienteExistente!.id!;
    } else {
      // Crear nuevo cliente
      final clientesProvider =
          Provider.of<ClientesProvider>(context, listen: false);
      final nuevoCliente = Cliente(
        dni: _dniController.text,
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
      );

      final resultado = await clientesProvider.crearCliente(nuevoCliente);
      if (!mounted) return;
      if (!resultado['success']) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al crear cliente: ${resultado['error']}')),
        );
        return;
      }
      // ClientesProvider devuelve {'success': true, 'cliente': Cliente}
      final created = resultado['cliente'];
      clienteId = created?.id ?? '';
    }

    final provider = Provider.of<AlquileresProvider>(context, listen: false);
    // Build articulos payload with id and cantidad
    final articulosPayload = _articulosSeleccionados.map((entry) {
      final art = entry['articulo'] as Articulo;
      final qty = entry['cantidad'] as int;
      return {'id': art.id, 'cantidad': qty};
    }).toList();

    final success = await provider.crearAlquiler(
      clienteId: clienteId,
      articulos: articulosPayload,
      trajesIds: [],
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      montoAlquiler: _totalAlquiler,
      garantia: double.parse(_garantiaController.text),
    );
    if (!mounted) return;

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
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

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
                  const SizedBox(height: 16),
                  _buildSeccionFechas(),
                  const SizedBox(height: 16),
                  _buildBotonesSeleccion(),
                  const SizedBox(height: 16),
                  _buildArticulosSeleccionados(),
                  const SizedBox(height: 16),
                  _buildSeccionGarantia(),
                  const SizedBox(height: 16),
                  _buildResumenYBoton(currencyFormat),
                  const SizedBox(height: 16),
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
            const Text('Datos del Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                helperText: 'Se autocompletará al ingresar 8 dígitos',
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              onChanged: (value) {
                if (value.length == 8) {
                  _buscarClientePorDni();
                }
              },
              validator: Validators.validateDni,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: Validators.validateNombre,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                helperText: '9 dígitos, inicia con 9',
              ),
              keyboardType: TextInputType.phone,
              maxLength: 9,
              validator: Validators.validateTelefono,
            ),
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
            const Text('Fechas del Alquiler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
                        setState(() {
                          _fechaInicio = picked;
                          if (_fechaFin.isBefore(_fechaInicio)) {
                            _fechaFin =
                                _fechaInicio.add(const Duration(days: 3));
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha Inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event),
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
                        prefixIcon: Icon(Icons.event_available),
                      ),
                      child: Text(dateFormat.format(_fechaFin)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Duración: $_diasAlquiler ${_diasAlquiler == 1 ? "día" : "días"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesSeleccion() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seleccionar Artículos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarArticulos,
                    icon: const Icon(Icons.checkroom),
                    label: const Text('Artículos Sueltos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      minimumSize: const Size(0, 56),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _seleccionarTraje,
                    icon: const Icon(Icons.style),
                    label: const Text('Desde Traje'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      minimumSize: const Size(0, 56),
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

  Widget _buildArticulosSeleccionados() {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Artículos Seleccionados',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_articulosSeleccionados.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_articulosSeleccionados.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay artículos seleccionados',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _articulosSeleccionados.length,
                itemBuilder: (context, index) {
                  final entry = _articulosSeleccionados[index];
                  final articulo = entry['articulo'] as Articulo;
                  final cantidad = entry['cantidad'] as int? ?? 1;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(articulo.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${articulo.tipo.toUpperCase()} - ${articulo.nombre}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(articulo.precioAlquiler),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Text('x$cantidad',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _articulosSeleccionados.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionGarantia() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Garantía',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _garantiaController,
              decoration: const InputDecoration(
                labelText: 'Monto de Garantía',
                border: OutlineInputBorder(),
                prefixText: 'S/ ',
                suffixIcon: Icon(Icons.attach_money),
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

  Widget _buildResumenYBoton(NumberFormat currencyFormat) {
    final garantia = double.tryParse(_garantiaController.text) ?? 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alquiler:', style: TextStyle(fontSize: 14)),
                Text(currencyFormat.format(_totalAlquiler),
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Garantía:', style: TextStyle(fontSize: 14)),
                Text(currencyFormat.format(garantia),
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL A PAGAR:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(_totalAlquiler + garantia),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _articulosSeleccionados.isEmpty ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text(
                  'GUARDAR ALQUILER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('CrearAlquilerScreen.dispose');
    _dniController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _garantiaController.dispose();
    super.dispose();
  }
}

// Diálogo para seleccionar artículos
class _DialogoSeleccionArticulos extends StatefulWidget {
  final List<Articulo> articulos;
  final List<dynamic> articulosYaSeleccionados;
  final String? tituloPersonalizado;
  final bool esAlquiler;

  const _DialogoSeleccionArticulos({
    required this.articulos,
    required this.articulosYaSeleccionados,
    this.tituloPersonalizado,
    this.esAlquiler = false,
  });

  @override
  State<_DialogoSeleccionArticulos> createState() =>
      __DialogoSeleccionArticulosState();
}

class __DialogoSeleccionArticulosState
    extends State<_DialogoSeleccionArticulos> {
  final Map<String, int> _selectedQuantities = {};
  final _searchController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    // Inicializar cantidades seleccionadas desde articulosYaSeleccionados
    for (final entry in widget.articulosYaSeleccionados) {
      if (entry is Map) {
        final art = entry['articulo'] as Articulo?;
        final id = art?.id ?? entry['id'];
        final qty = entry['cantidad'] as int? ?? 1;
        if (id != null) _selectedQuantities[id] = qty;
      } else if (entry is Articulo) {
        if (entry.id != null) _selectedQuantities[entry.id!] = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final articulosFiltrados = widget.articulos.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombre.toLowerCase().contains(query) ||
          a.tipo.toLowerCase().contains(query) ||
          (a.talla?.toLowerCase().contains(query) ?? false);
    }).toList();

    return AlertDialog(
      title: Text(widget.tituloPersonalizado ?? 'Seleccionar Artículos'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _filtro = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: articulosFiltrados.length,
                itemBuilder: (context, index) {
                  final articulo = articulosFiltrados[index];
                  final disponible = articulo.cantidadDisponible;
                  final seleccionado =
                      _selectedQuantities.containsKey(articulo.id);
                  final precio = widget.esAlquiler
                      ? articulo.precioAlquiler
                      : articulo.precioVenta;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(articulo.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                    '${articulo.tipo.toUpperCase()} - ${articulo.nombre}\n${currencyFormat.format(precio)}'),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(seleccionado
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                                onPressed: () {
                                  setState(() {
                                    if (seleccionado) {
                                      _selectedQuantities.remove(articulo.id);
                                    } else {
                                      _selectedQuantities[articulo.id!] = 1;
                                    }
                                  });
                                },
                              ),
                              if (seleccionado) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: () {
                                        setState(() {
                                          final cur = _selectedQuantities[
                                              articulo.id!]!;
                                          if (cur > 1) {
                                            _selectedQuantities[articulo.id!] =
                                                cur - 1;
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                        '${_selectedQuantities[articulo.id!]}'),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        setState(() {
                                          final cur = _selectedQuantities[
                                              articulo.id!]!;
                                          final maxQty = disponible;
                                          if (cur < maxQty) {
                                            _selectedQuantities[articulo.id!] =
                                                cur + 1;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                )
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Construir resultado: lista de { 'articulo': Articulo, 'cantidad': int }
            final result = <Map<String, dynamic>>[];
            for (final entry in _selectedQuantities.entries) {
              final art = widget.articulos.firstWhere((a) => a.id == entry.key);
              result.add({'articulo': art, 'cantidad': entry.value});
            }
            Navigator.pop(context, result);
          },
          icon: const Icon(Icons.check),
          label: Text('Aceptar (${_selectedQuantities.length})'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Diálogo para seleccionar traje
class _DialogoSeleccionTraje extends StatefulWidget {
  final List<Traje> trajes;

  const _DialogoSeleccionTraje({required this.trajes});

  @override
  State<_DialogoSeleccionTraje> createState() => __DialogoSeleccionTrajeState();
}

class __DialogoSeleccionTrajeState extends State<_DialogoSeleccionTraje> {
  final _searchController = TextEditingController();
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final trajesFiltrados = widget.trajes.where((t) {
      final query = _filtro.toLowerCase();
      return t.nombre.toLowerCase().contains(query) ||
          (t.descripcion?.toLowerCase().contains(query) ?? false);
    }).toList();

    return AlertDialog(
      title: const Text('Seleccionar Traje'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar traje',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _filtro = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: trajesFiltrados.length,
                itemBuilder: (context, index) {
                  final traje = trajesFiltrados[index];
                  final disponibles = traje.articulos
                      .where((a) => a.cantidadDisponible > 0)
                      .length;
                  final total = traje.articulos.length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.checkroom),
                      ),
                      title: Text(traje.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${traje.descripcion ?? ""}\n$disponibles/$total piezas disponibles',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.pop(context, traje),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
