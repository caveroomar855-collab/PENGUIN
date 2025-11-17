import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  String _filtroEstado = 'todos'; // todos, disponible, alquilado, mantenimiento

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
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
            Tab(text: 'Artículos', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Trajes', icon: Icon(Icons.checkroom)),
            Tab(text: 'Estados', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArticulos(),
          _buildTrajes(),
          _buildEstados(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearArticulo,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Artículo'),
              backgroundColor: Colors.orange,
            )
          : _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: _mostrarDialogoCrearTraje,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Traje'),
                  backgroundColor: Colors.blue,
                )
              : null,
    );
  }

  Widget _buildArticulos() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar artículo',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFiltroChip('Todos', 'todos'),
                    _buildFiltroChip('Disponible', 'disponible'),
                    _buildFiltroChip('Alquilado', 'alquilado'),
                    _buildFiltroChip('Mantenimiento', 'mantenimiento'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<InventarioProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              var articulos = provider.articulos.where((a) {
                // Filtro por búsqueda
                if (_searchQuery.isNotEmpty) {
                  final matchSearch = a.nombre.toLowerCase().contains(_searchQuery) ||
                      a.codigo.toLowerCase().contains(_searchQuery) ||
                      a.tipo.toLowerCase().contains(_searchQuery) ||
                      (a.color?.toLowerCase().contains(_searchQuery) ?? false);
                  if (!matchSearch) return false;
                }

                // Filtro por estado
                if (_filtroEstado != 'todos') {
                  return a.estado == _filtroEstado;
                }

                return true;
              }).toList();

              if (articulos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No hay artículos'
                            : 'No se encontraron artículos',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _cargarDatos,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: articulos.length,
                  itemBuilder: (context, index) {
                    return _buildArticuloCard(articulos[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final seleccionado = _filtroEstado == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: seleccionado,
        onSelected: (selected) {
          setState(() => _filtroEstado = valor);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: _getEstadoColor(valor == 'todos' ? 'disponible' : valor),
        labelStyle: TextStyle(
          color: seleccionado ? Colors.white : Colors.black87,
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildArticuloCard(Articulo articulo) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final enMantenimiento = articulo.estado == 'mantenimiento';
    final disponibleEn = articulo.fechaDisponible;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEstadoColor(articulo.estado),
          child: Icon(
            _getIconoTipo(articulo.tipo),
            color: Colors.white,
          ),
        ),
        title: Text(
          articulo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${articulo.tipo.toUpperCase()} - ${articulo.codigo}'),
            if (articulo.talla != null) Text('Talla: ${articulo.talla}'),
            if (articulo.color != null) Text('Color: ${articulo.color}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(articulo.estado),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    articulo.estado.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (enMantenimiento && disponibleEn != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Hasta: ${dateFormat.format(disponibleEn)}',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ver',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Ver Detalles'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mantenimiento',
              child: Row(
                children: [
                  Icon(Icons.build, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Gestionar Mantenimiento'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'ver':
                _mostrarDetalleArticulo(articulo);
                break;
              case 'editar':
                _mostrarDialogoEditarArticulo(articulo);
                break;
              case 'mantenimiento':
                _mostrarDialogoMantenimiento(articulo);
                break;
              case 'eliminar':
                _confirmarEliminarArticulo(articulo);
                break;
            }
          },
        ),
        onTap: () => _mostrarDetalleArticulo(articulo),
      ),
    );
  }

  Widget _buildTrajes() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar traje',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
        ),
        Expanded(
          child: Consumer<InventarioProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final trajes = provider.trajes.where((t) {
                if (_searchQuery.isEmpty) return true;
                return t.nombre.toLowerCase().contains(_searchQuery) ||
                    (t.descripcion?.toLowerCase().contains(_searchQuery) ?? false);
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

              return RefreshIndicator(
                onRefresh: _cargarDatos,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trajes.length,
                  itemBuilder: (context, index) {
                    return _buildTrajeCard(trajes[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrajeCard(Traje traje) {
    final disponibles =
        traje.articulos.where((a) => a.estado == 'disponible').length;
    final alquilados =
        traje.articulos.where((a) => a.estado == 'alquilado').length;
    final mantenimiento =
        traje.articulos.where((a) => a.estado == 'mantenimiento').length;
    final todosDisponibles = disponibles == traje.articulos.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: todosDisponibles ? Colors.green : Colors.orange,
          child: const Icon(Icons.checkroom, color: Colors.white),
        ),
        title: Text(traje.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (traje.descripcion != null) Text(traje.descripcion!),
            const SizedBox(height: 4),
            Text('${traje.articulos.length} piezas - $disponibles disponibles'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'editar') {
              _mostrarDialogoEditarTraje(traje);
            } else if (value == 'eliminar') {
              _confirmarEliminarTraje(traje);
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEstadoBadge(
                    'Disponibles', disponibles, Colors.green),
                _buildEstadoBadge('Alquilados', alquilados, Colors.blue),
                _buildEstadoBadge(
                    'Mantenimiento', mantenimiento, Colors.orange),
              ],
            ),
          ),
          const Divider(height: 1),
          ...traje.articulos.map((articulo) {
            return ListTile(
              dense: true,
              leading: Icon(
                _getIconoTipo(articulo.tipo),
                size: 20,
                color: _getEstadoColor(articulo.estado),
              ),
              title: Text(articulo.nombre),
              subtitle: Text('${articulo.codigo} - ${articulo.estado}'),
              trailing: Icon(Icons.circle,
                  size: 12, color: _getEstadoColor(articulo.estado)),
              onTap: () => _mostrarDetalleArticulo(articulo),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String label, int cantidad, Color color) {
    return Column(
      children: [
        Text(
          cantidad.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEstados() {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final total = provider.articulos.length;
        final disponibles =
            provider.articulos.where((a) => a.estado == 'disponible').length;
        final alquilados =
            provider.articulos.where((a) => a.estado == 'alquilado').length;
        final mantenimiento =
            provider.articulos.where((a) => a.estado == 'mantenimiento').length;
        final vendidos =
            provider.articulos.where((a) => a.estado == 'vendido').length;
        final perdidos =
            provider.articulos.where((a) => a.estado == 'perdido').length;

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2,
                          size: 60, color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'Total de Artículos',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        total.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Desglose por Estado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildEstadoCard('Disponibles', disponibles, total, Colors.green,
                  Icons.check_circle),
              _buildEstadoCard('Alquilados', alquilados, total, Colors.blue,
                  Icons.event_available),
              _buildEstadoCard('En Mantenimiento', mantenimiento, total,
                  Colors.orange, Icons.build),
              _buildEstadoCard(
                  'Vendidos', vendidos, total, Colors.purple, Icons.shopping_bag),
              _buildEstadoCard(
                  'Perdidos', perdidos, total, Colors.red, Icons.error),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadoCard(
      String label, int cantidad, int total, Color color, IconData icon) {
    final porcentaje = total > 0 ? (cantidad / total * 100).toStringAsFixed(1) : '0.0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: LinearProgressIndicator(
          value: total > 0 ? cantidad / total : 0,
          backgroundColor: Colors.grey[200],
          color: color,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              cantidad.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$porcentaje%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogos y acciones
  Future<void> _mostrarDetalleArticulo(Articulo articulo) async {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(articulo.nombre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleRow('Código:', articulo.codigo),
              _buildDetalleRow('Tipo:', articulo.tipo.toUpperCase()),
              if (articulo.talla != null)
                _buildDetalleRow('Talla:', articulo.talla!),
              if (articulo.color != null)
                _buildDetalleRow('Color:', articulo.color!),
              const Divider(height: 24),
              _buildDetalleRow(
                  'Precio Alquiler:', currencyFormat.format(articulo.precioAlquiler)),
              _buildDetalleRow(
                  'Precio Venta:', currencyFormat.format(articulo.precioVenta)),
              const Divider(height: 24),
              _buildDetalleRow(
                'Estado:',
                articulo.estado.toUpperCase(),
                color: _getEstadoColor(articulo.estado),
              ),
              if (articulo.estado == 'mantenimiento' &&
                  articulo.fechaDisponible != null)
                _buildDetalleRow(
                  'Disponible el:',
                  dateFormat.format(articulo.fechaDisponible!),
                  color: Colors.orange,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (articulo.estado == 'mantenimiento')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogoMantenimiento(articulo);
              },
              icon: const Icon(Icons.build),
              label: const Text('Gestionar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child:
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _mostrarDialogoMantenimiento(Articulo articulo) async {
    int? horas = 24;
    bool indefinido = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Gestionar Mantenimiento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Artículo: ${articulo.nombre}'),
                Text('Estado actual: ${articulo.estado}'),
                const Divider(height: 24),
                if (articulo.estado == 'mantenimiento') ...[
                  const Text('¿Desea quitar de mantenimiento?'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final provider = Provider.of<InventarioProvider>(
                          context,
                          listen: false);
                      final resultado = await provider
                          .cambiarEstadoArticulo(articulo.id!, 'disponible');

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(resultado
                                ? 'Artículo disponible nuevamente'
                                : 'Error al actualizar'),
                            backgroundColor:
                                resultado ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marcar como Disponible'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  const Text('¿Por cuánto tiempo?'),
                  const SizedBox(height: 16),
                  RadioListTile<int>(
                    title: const Text('24 horas (Perfecta condición)'),
                    value: 24,
                    groupValue: indefinido ? null : horas,
                    onChanged: indefinido
                        ? null
                        : (value) {
                            setDialogState(() => horas = value);
                          },
                  ),
                  RadioListTile<int>(
                    title: const Text('72 horas (Dañado)'),
                    value: 72,
                    groupValue: indefinido ? null : horas,
                    onChanged: indefinido
                        ? null
                        : (value) {
                            setDialogState(() => horas = value);
                          },
                  ),
                  CheckboxListTile(
                    title: const Text('Tiempo indefinido'),
                    value: indefinido,
                    onChanged: (value) {
                      setDialogState(() => indefinido = value ?? false);
                    },
                  ),
                  if (!indefinido) ...[
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Horas personalizadas',
                        border: OutlineInputBorder(),
                        suffixText: 'horas',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null) {
                          setDialogState(() => horas = parsed);
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            if (articulo.estado != 'mantenimiento')
              ElevatedButton(
                onPressed: () async {
                  final provider =
                      Provider.of<InventarioProvider>(context, listen: false);

                  DateTime? fechaDisponible;
                  if (!indefinido && horas != null) {
                    fechaDisponible =
                        DateTime.now().add(Duration(hours: horas!));
                  }

                  final resultado = await provider.ponerEnMantenimiento(
                    articulo.id!,
                    fechaDisponible,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(resultado
                            ? 'Artículo en mantenimiento'
                            : 'Error al actualizar'),
                        backgroundColor: resultado ? Colors.orange : Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Poner en Mantenimiento'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoCrearArticulo() async {
    final codigoController = TextEditingController();
    final nombreController = TextEditingController();
    String tipo = 'saco';
    final tallaController = TextEditingController();
    final colorController = TextEditingController();
    final precioAlquilerController = TextEditingController();
    final precioVentaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Artículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'saco', child: Text('Saco')),
                    DropdownMenuItem(value: 'chaleco', child: Text('Chaleco')),
                    DropdownMenuItem(value: 'pantalon', child: Text('Pantalón')),
                    DropdownMenuItem(value: 'camisa', child: Text('Camisa')),
                    DropdownMenuItem(value: 'zapato', child: Text('Zapato')),
                    DropdownMenuItem(value: 'extra', child: Text('Extra (Corbatas, etc.)')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => tipo = value!);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tallaController,
                  decoration: const InputDecoration(
                    labelText: 'Talla',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precioAlquilerController,
                  decoration: const InputDecoration(
                    labelText: 'Precio Alquiler *',
                    border: OutlineInputBorder(),
                    prefixText: 'S/ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precioVentaController,
                  decoration: const InputDecoration(
                    labelText: 'Precio Venta *',
                    border: OutlineInputBorder(),
                    prefixText: 'S/ ',
                  ),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                if (codigoController.text.isEmpty ||
                    nombreController.text.isEmpty ||
                    precioAlquilerController.text.isEmpty ||
                    precioVentaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete los campos obligatorios')),
                  );
                  return;
                }

                final nuevoArticulo = Articulo(
                  codigo: codigoController.text,
                  nombre: nombreController.text,
                  tipo: tipo,
                  talla: tallaController.text.isEmpty ? null : tallaController.text,
                  color: colorController.text.isEmpty ? null : colorController.text,
                  precioAlquiler: double.parse(precioAlquilerController.text),
                  precioVenta: double.parse(precioVentaController.text),
                  estado: 'disponible',
                );

                final provider =
                    Provider.of<InventarioProvider>(context, listen: false);
                final resultado = await provider.crearArticulo(nuevoArticulo);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(resultado['success']
                          ? 'Artículo creado exitosamente'
                          : 'Error: ${resultado['error']}'),
                      backgroundColor:
                          resultado['success'] ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoEditarArticulo(Articulo articulo) async {
    final nombreController = TextEditingController(text: articulo.nombre);
    final tallaController = TextEditingController(text: articulo.talla ?? '');
    final colorController = TextEditingController(text: articulo.color ?? '');
    final precioAlquilerController =
        TextEditingController(text: articulo.precioAlquiler.toString());
    final precioVentaController =
        TextEditingController(text: articulo.precioVenta.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Artículo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tallaController,
                decoration: const InputDecoration(
                  labelText: 'Talla',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioAlquilerController,
                decoration: const InputDecoration(
                  labelText: 'Precio Alquiler *',
                  border: OutlineInputBorder(),
                  prefixText: 'S/ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioVentaController,
                decoration: const InputDecoration(
                  labelText: 'Precio Venta *',
                  border: OutlineInputBorder(),
                  prefixText: 'S/ ',
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nombreController.text.isEmpty ||
                  precioAlquilerController.text.isEmpty ||
                  precioVentaController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complete los campos obligatorios')),
                );
                return;
              }

              final articuloActualizado = Articulo(
                id: articulo.id,
                codigo: articulo.codigo,
                nombre: nombreController.text,
                tipo: articulo.tipo,
                talla: tallaController.text.isEmpty ? null : tallaController.text,
                color: colorController.text.isEmpty ? null : colorController.text,
                precioAlquiler: double.parse(precioAlquilerController.text),
                precioVenta: double.parse(precioVentaController.text),
                estado: articulo.estado,
                fechaDisponible: articulo.fechaDisponible,
              );

              final provider =
                  Provider.of<InventarioProvider>(context, listen: false);
              final resultado = await provider.actualizarArticulo(
                  articulo.id!, articuloActualizado);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resultado
                        ? 'Artículo actualizado exitosamente'
                        : 'Error al actualizar artículo'),
                    backgroundColor: resultado ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarArticulo(Articulo articulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Está seguro de eliminar el artículo ${articulo.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final provider = Provider.of<InventarioProvider>(context, listen: false);
      final resultado = await provider.eliminarArticulo(articulo.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado
                ? 'Artículo eliminado exitosamente'
                : 'Error al eliminar artículo'),
            backgroundColor: resultado ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoCrearTraje() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crear traje en desarrollo')),
    );
  }

  Future<void> _mostrarDialogoEditarTraje(Traje traje) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar traje en desarrollo')),
    );
  }

  Future<void> _confirmarEliminarTraje(Traje traje) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eliminar traje en desarrollo')),
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
      case 'vendido':
        return Colors.purple;
      case 'perdido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'saco':
        return Icons.checkroom;
      case 'chaleco':
        return Icons.vpn_key;
      case 'pantalon':
        return Icons.boy;
      case 'camisa':
        return Icons.dry_cleaning;
      case 'zapato':
        return Icons.directions_walk;
      case 'extra':
        return Icons.shopping_bag;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
