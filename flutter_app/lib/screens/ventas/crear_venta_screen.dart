import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/ventas_provider.dart';
import '../../providers/clientes_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../models/articulo.dart';
import '../../models/traje.dart';
import '../../utils/validators.dart';

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({super.key});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _observacionesController = TextEditingController();

  Cliente? _clienteExistente;
  List<Articulo> _articulosSeleccionados = [];
  String _metodoPago = 'efectivo';
  bool _buscandoCliente = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final inventarioProvider =
        Provider.of<InventarioProvider>(context, listen: false);
    await inventarioProvider.cargarArticulos();
    await inventarioProvider.cargarTrajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccionCliente(),
              const SizedBox(height: 24),
              _buildSeccionArticulos(),
              const SizedBox(height: 24),
              _buildSeccionPago(),
              const SizedBox(height: 24),
              _buildSeccionObservaciones(),
              const SizedBox(height: 32),
              _buildBotonGuardar(),
            ],
          ),
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
              decoration: InputDecoration(
                labelText: 'DNI *',
                helperText: '8 dígitos (busca automáticamente)',
                border: const OutlineInputBorder(),
                suffixIcon: _buscandoCliente
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _buscarClientePorDni,
                        tooltip: 'Buscar cliente',
                      ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              validator: Validators.validateDni,
              onChanged: (value) {
                if (_clienteExistente != null) {
                  setState(() {
                    _clienteExistente = null;
                    _nombreController.clear();
                    _telefonoController.clear();
                  });
                }
                // Buscar automáticamente cuando el DNI tenga 8 dígitos
                if (value.length == 8 && RegExp(r'^\d{8}$').hasMatch(value)) {
                  _buscarClientePorDni();
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo *',
                border: OutlineInputBorder(),
              ),
              validator: Validators.validateNombre,
              textCapitalization: TextCapitalization.words,
              enabled: _clienteExistente == null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono *',
                helperText: '9 dígitos, inicia con 9',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 9,
              validator: Validators.validateTelefono,
              enabled: _clienteExistente == null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionArticulos() {
    final total = _articulosSeleccionados.fold<double>(
      0,
      (sum, art) => sum + art.precioVenta,
    );
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
                const Text('Artículos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Total: ${currencyFormat.format(total)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _seleccionarArticulos,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Seleccionar Artículos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _seleccionarTraje,
                    icon: const Icon(Icons.checkroom),
                    label: const Text('Seleccionar Traje'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            if (_articulosSeleccionados.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _articulosSeleccionados.length,
                itemBuilder: (context, index) {
                  final articulo = _articulosSeleccionados[index];
                  return ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(articulo.nombre),
                    subtitle: Text(
                        '${articulo.tipo.toUpperCase()} - ${articulo.codigo}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(articulo.precioVenta),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
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
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionPago() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Método de Pago',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _metodoPago,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                DropdownMenuItem(value: 'yape', child: Text('Yape/Plin')),
                DropdownMenuItem(
                    value: 'transferencia', child: Text('Transferencia')),
              ],
              onChanged: (value) {
                setState(() => _metodoPago = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionObservaciones() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Observaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                hintText: 'Notas adicionales sobre la venta...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _articulosSeleccionados.isEmpty ? null : _guardarVenta,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.green,
          disabledBackgroundColor: Colors.grey,
        ),
        child: const Text(
          'GUARDAR VENTA',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _buscarClientePorDni() async {
    if (_dniController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un DNI')),
      );
      return;
    }

    setState(() => _buscandoCliente = true);

    final provider = Provider.of<ClientesProvider>(context, listen: false);
    final cliente = await provider.buscarPorDni(_dniController.text);

    setState(() => _buscandoCliente = false);

    if (cliente != null) {
      setState(() {
        _clienteExistente = cliente;
        _nombreController.text = cliente.nombre;
        _telefonoController.text = cliente.telefono;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cliente encontrado'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cliente no encontrado. Complete los datos.'),
            backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _seleccionarArticulos() async {
    final inventarioProvider =
        Provider.of<InventarioProvider>(context, listen: false);
    final articulosDisponibles = inventarioProvider.articulos
        .where((a) => a.cantidadDisponible > 0)
        .toList();

    if (articulosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay artículos disponibles')),
      );
      return;
    }

    final seleccionados = await showDialog<List<Articulo>>(
      context: context,
      builder: (context) => _DialogoSeleccionArticulos(
        articulos: articulosDisponibles,
        articulosYaSeleccionados: _articulosSeleccionados,
      ),
    );

    if (seleccionados != null) {
      setState(() {
        _articulosSeleccionados = seleccionados;
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

      final seleccionados = await showDialog<List<Articulo>>(
        context: context,
        builder: (context) => _DialogoSeleccionArticulos(
          articulos: articulosDisponibles,
          articulosYaSeleccionados: _articulosSeleccionados,
          tituloPersonalizado: 'Artículos del Traje: ${traje.nombre}',
        ),
      );

      if (seleccionados != null) {
        setState(() {
          _articulosSeleccionados = seleccionados;
        });
      }
    }
  }

  Future<void> _guardarVenta() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_articulosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos un artículo')),
      );
      return;
    }

    // Crear o usar cliente existente
    String clienteId;
    if (_clienteExistente != null) {
      clienteId = _clienteExistente!.id!;
    } else {
      final clientesProvider =
          Provider.of<ClientesProvider>(context, listen: false);
      final nuevoCliente = Cliente(
        dni: _dniController.text,
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
      );
      final resultado = await clientesProvider.crearCliente(nuevoCliente);
      if (resultado['success']) {
        clienteId = resultado['cliente'].id!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${resultado['error']}'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    final total = _articulosSeleccionados.fold<double>(
      0,
      (sum, art) => sum + art.precioVenta,
    );

    final nuevaVenta = Venta(
      clienteId: clienteId,
      total: total,
      metodoPago: _metodoPago,
      articulos: _articulosSeleccionados
          .map((a) => VentaArticulo(
                ventaId: '',
                articuloId: a.id!,
                precio: a.precioVenta,
              ))
          .toList(),
    );

    final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
    final resultado = await ventasProvider.crearVenta(nuevaVenta);

    if (mounted) {
      if (resultado) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Venta registrada exitosamente'),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al registrar venta'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}

// Diálogo para seleccionar artículos
class _DialogoSeleccionArticulos extends StatefulWidget {
  final List<Articulo> articulos;
  final List<Articulo> articulosYaSeleccionados;
  final String? tituloPersonalizado;

  const _DialogoSeleccionArticulos({
    required this.articulos,
    required this.articulosYaSeleccionados,
    this.tituloPersonalizado,
  });

  @override
  State<_DialogoSeleccionArticulos> createState() =>
      __DialogoSeleccionArticulosState();
}

class __DialogoSeleccionArticulosState
    extends State<_DialogoSeleccionArticulos> {
  late List<Articulo> _seleccionados;
  final _searchController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _seleccionados = List.from(widget.articulosYaSeleccionados);
  }

  @override
  Widget build(BuildContext context) {
    final articulosFiltrados = widget.articulos.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombre.toLowerCase().contains(query) ||
          a.codigo.toLowerCase().contains(query) ||
          a.tipo.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: Text(widget.tituloPersonalizado ?? 'Seleccionar Artículos'),
      content: SizedBox(
        width: double.maxFinite,
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
                  final seleccionado = _seleccionados.contains(articulo);
                  return CheckboxListTile(
                    value: seleccionado,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _seleccionados.add(articulo);
                        } else {
                          _seleccionados.remove(articulo);
                        }
                      });
                    },
                    title: Text(articulo.nombre),
                    subtitle: Text(
                        '${articulo.tipo.toUpperCase()} - ${articulo.codigo}\nS/ ${articulo.precioVenta.toStringAsFixed(2)}'),
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
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _seleccionados),
          child: Text('Aceptar (${_seleccionados.length})'),
        ),
      ],
    );
  }
}

// Diálogo para seleccionar traje
class _DialogoSeleccionTraje extends StatelessWidget {
  final List<Traje> trajes;

  const _DialogoSeleccionTraje({required this.trajes});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Traje'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: trajes.length,
          itemBuilder: (context, index) {
            final traje = trajes[index];
            final disponibles =
                traje.articulos.where((a) => a.cantidadDisponible > 0).length;
            return ListTile(
              title: Text(traje.nombre),
              subtitle: Text(
                  '${traje.articulos.length} artículos ($disponibles disponibles)'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.pop(context, traje),
            );
          },
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
}
