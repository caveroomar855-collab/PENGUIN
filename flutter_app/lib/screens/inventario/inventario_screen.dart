import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventario_provider.dart';
import 'historial_screen.dart';
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
    _tabController.addListener(() {
      setState(() {}); // Reconstruir para actualizar el FAB
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    final provider = Provider.of<InventarioProvider>(context, listen: false);
    await provider.cargarArticulos();
    await provider.cargarTrajes();
    await provider.cargarResumenEstados();
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
                if (_searchQuery.isNotEmpty) {
                  final matchSearch = a.nombre
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      a.codigo.toLowerCase().contains(_searchQuery) ||
                      a.tipo.toLowerCase().contains(_searchQuery) ||
                      (a.color?.toLowerCase().contains(_searchQuery) ?? false);
                  if (!matchSearch) return false;
                }

                if (_filtroEstado != 'todos') {
                  switch (_filtroEstado) {
                    case 'disponible':
                      return a.cantidadDisponible > 0;
                    case 'alquilado':
                      return a.cantidadAlquilada > 0;
                    case 'mantenimiento':
                      return a.cantidadMantenimiento > 0;
                    default:
                      return true;
                  }
                }

                return true;
              }).toList();

              if (articulos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No hay artículos'
                            : 'No se encontraron artículos',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.grey),
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
    final enMantenimiento = articulo.cantidadMantenimiento > 0;
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
        title: Text(articulo.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${articulo.tipo.toUpperCase()} - ${articulo.codigo}'),
            if (articulo.talla != null) Text('Talla: ${articulo.talla}'),
            if (articulo.color != null) Text('Color: ${articulo.color}'),
            Text(
              'Stock: ${articulo.cantidadDisponible}/${articulo.cantidad} disponibles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    articulo.cantidadDisponible > 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (articulo.cantidadAlquilada > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${articulo.cantidadAlquilada} alq.',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                if (articulo.cantidadMantenimiento > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${articulo.cantidadMantenimiento} mant.',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                if (enMantenimiento && disponibleEn != null) ...[
                  const SizedBox(width: 8),
                  Text('Hasta: ${dateFormat.format(disponibleEn)}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.orange)),
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
                    (t.descripcion?.toLowerCase().contains(_searchQuery) ??
                        false);
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
    final disponibles = traje.articulos.isEmpty
        ? 0
        : traje.articulos
            .map((a) => a.cantidadDisponible)
            .reduce((v, e) => v < e ? v : e);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: disponibles > 0 ? Colors.green : Colors.orange,
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
                _buildEstadoBadge('Disponibles', disponibles, Colors.green),
              ],
            ),
          ),
          const Divider(height: 1),
          ...traje.articulos.map((articulo) {
            return ListTile(
              dense: true,
              leading: Icon(_getIconoTipo(articulo.tipo),
                  size: 20, color: _getEstadoColor(articulo.estado)),
              title: Text(articulo.nombre),
              subtitle: Text(
                  '${articulo.codigo} - Stock: ${articulo.cantidadDisponible}/${articulo.cantidad}'),
              trailing: Icon(Icons.circle,
                  size: 12, color: _getEstadoColor(articulo.estado)),
              onTap: () => _mostrarDetalleArticulo(articulo),
            );
          }),
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
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEstados() {
    return Consumer<InventarioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final resumen = provider.estadosResumen;
        final total = resumen['total'] ?? provider.articulos.length;

        Widget buildEstadoExpansion(
            String tipoKey, String label, Color color, IconData icon) {
          final cantidad = resumen[tipoKey] ?? 0;
          return ExpansionTile(
            leading: CircleAvatar(
                backgroundColor: color, child: Icon(icon, color: Colors.white)),
            title: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$cantidad artículos'),
            onExpansionChanged: (open) {
              if (open) {
                // Trigger a background refresh when user opens the tile.
                provider.cargarListaEstado(tipoKey);
              }
            },
            children: [
              // Use provider state directly to avoid FutureBuilder waiting loops.
              Builder(builder: (context) {
                // Prefer the cached RPC list. If it's empty, build a fallback
                // from the in-memory `articulos` so the user sees names + qty
                // even when the list RPC times out.
                final cachedItems = provider.getEstadoList(tipoKey);
                final loading = provider.isLoadingEstado(tipoKey);
                final error = provider.getEstadoError(tipoKey);

                List<Map<String, dynamic>> items = cachedItems;
                if (items.isEmpty) {
                  // Build fallback from articles in provider
                  items = provider.articulos
                      .map((a) {
                        int qty = 0;
                        switch (tipoKey) {
                          case 'disponibles':
                            qty = a.cantidadDisponible;
                            break;
                          case 'alquilados':
                            qty = a.cantidadAlquilada;
                            break;
                          case 'mantenimiento':
                            qty = a.cantidadMantenimiento;
                            break;
                          case 'vendidos':
                            qty = a.cantidadVendida;
                            break;
                          case 'perdidos':
                            qty = a.cantidadPerdida;
                            break;
                          default:
                            qty = 0;
                        }
                        return {
                          'id': a.id,
                          'nombre': a.nombre,
                          'cantidad': qty
                        };
                      })
                      .where((m) => (m['cantidad'] as int) > 0)
                      .toList();
                }

                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if ((items.isEmpty) && error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text('Error cargando: $error',
                                style: const TextStyle(color: Colors.red))),
                        TextButton(
                          onPressed: () {
                            provider.cargarListaEstado(tipoKey);
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay artículos'),
                  );
                }

                return Column(
                  children: items.map((a) {
                    return ListTile(
                      title: Text(a['nombre'] ?? ''),
                      trailing: Text((a['cantidad'] ?? 0).toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () {},
                    );
                  }).toList(),
                );
              })
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _cargarDatos,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Historial compacto (hasta 3 eventos)
              Builder(builder: (context) {
                final provider = Provider.of<InventarioProvider>(context);
                final recent = provider.historial.take(3).toList();
                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Historial',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const HistorialScreen()));
                              },
                              child: const Text('Ver todo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (recent.isEmpty)
                          const Text('No hay eventos recientes',
                              style: TextStyle(color: Colors.grey))
                        else
                          ...recent.map((e) {
                            final ts =
                                DateTime.tryParse(e['timestamp'] ?? '') ??
                                    DateTime.now();
                            final mensaje = e['mensaje'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(mensaje,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('dd/MM HH:mm').format(ts),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              // Total de Artículos (compact)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Total de Artículos',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          SizedBox(height: 4),
                        ],
                      ),
                      Text(total.toString(),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Desglose por Estado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              buildEstadoExpansion('disponibles', 'Disponibles', Colors.green,
                  Icons.check_circle),
              buildEstadoExpansion('alquilados', 'Alquilados', Colors.blue,
                  Icons.event_available),
              buildEstadoExpansion('mantenimiento', 'En Mantenimiento',
                  Colors.orange, Icons.build),
              buildEstadoExpansion(
                  'vendidos', 'Vendidos', Colors.purple, Icons.shopping_bag),
              buildEstadoExpansion(
                  'perdidos', 'Perdidos', Colors.red, Icons.error),
            ],
          ),
        );
      },
    );
  }

  // Diálogos y acciones
  Future<void> _mostrarDetalleArticulo(Articulo articulo) async {
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final enMantenimiento = articulo.cantidadMantenimiento > 0;

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
              _buildDetalleRow('Precio Alquiler:',
                  currencyFormat.format(articulo.precioAlquiler)),
              _buildDetalleRow(
                  'Precio Venta:', currencyFormat.format(articulo.precioVenta)),
              const Divider(height: 24),
              // Mostrar desglose por cantidades
              _buildDetalleRow('DISPONIBLE:',
                  '${articulo.cantidadDisponible} / ${articulo.cantidad}'),
              _buildDetalleRow('ALQUILADO:', '${articulo.cantidadAlquilada}'),
              _buildDetalleRow(
                  'MANTENIMIENTO:', '${articulo.cantidadMantenimiento}'),
              if (enMantenimiento && articulo.fechaDisponible != null)
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
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
    int cantidad = 1;
    final outerContext = context;

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
                Text('Artículo: ${articulo.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Stock total: ${articulo.cantidad}'),
                Text('Disponibles: ${articulo.cantidadDisponible}',
                    style: const TextStyle(color: Colors.green)),
                Text('En mantenimiento: ${articulo.cantidadMantenimiento}',
                    style: const TextStyle(color: Colors.orange)),
                Text('Alquilados: ${articulo.cantidadAlquilada}',
                    style: const TextStyle(color: Colors.blue)),
                const Divider(height: 24),
                if (articulo.cantidadMantenimiento > 0) ...[
                  const Text('Unidades en mantenimiento:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cantidad a quitar de mantenimiento',
                      border: OutlineInputBorder(),
                      helperText: 'Dejar en blanco para quitar todas',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null &&
                          parsed <= articulo.cantidadMantenimiento) {
                        setDialogState(() => cantidad = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final provider = Provider.of<InventarioProvider>(
                          outerContext,
                          listen: false);
                      final resultado = await provider.gestionarMantenimiento(
                        articulo.id!,
                        'quitar',
                        cantidad,
                      );

                      if (!mounted) return;
                      Navigator.pop(outerContext);
                      ScaffoldMessenger.of(outerContext).showSnackBar(
                        SnackBar(
                          content: Text(resultado
                              ? '$cantidad unidad(es) disponible(s) nuevamente'
                              : 'Error al actualizar'),
                          backgroundColor:
                              resultado ? Colors.green : Colors.red,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Quitar de Mantenimiento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const Divider(height: 24),
                ],
                if (articulo.cantidadDisponible > 0) ...[
                  const Text('Poner unidades en mantenimiento:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: const OutlineInputBorder(),
                      helperText: 'Máximo: ${articulo.cantidadDisponible}',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null &&
                          parsed > 0 &&
                          parsed <= articulo.cantidadDisponible) {
                        setDialogState(() => cantidad = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('¿Por cuánto tiempo?'),
                  const SizedBox(height: 8),
                  RadioListTile<int>(
                    dense: true,
                    title: const Text('24 horas'),
                    value: 24,
                    groupValue: indefinido ? null : horas,
                    onChanged: indefinido
                        ? null
                        : (value) {
                            setDialogState(() => horas = value);
                          },
                  ),
                  RadioListTile<int>(
                    dense: true,
                    title: const Text('72 horas'),
                    value: 72,
                    groupValue: indefinido ? null : horas,
                    onChanged: indefinido
                        ? null
                        : (value) {
                            setDialogState(() => horas = value);
                          },
                  ),
                  CheckboxListTile(
                    dense: true,
                    title: const Text('Tiempo indefinido'),
                    value: indefinido,
                    onChanged: (value) {
                      setDialogState(() => indefinido = value ?? false);
                    },
                  ),
                  if (!indefinido) ...[
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Horas personalizadas',
                        border: OutlineInputBorder(),
                        suffixText: 'hrs',
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (cantidad <= 0 ||
                          cantidad > articulo.cantidadDisponible) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cantidad inválida')),
                        );
                        return;
                      }

                      final provider = Provider.of<InventarioProvider>(
                          outerContext,
                          listen: false);
                      final resultado = await provider.gestionarMantenimiento(
                        articulo.id!,
                        'agregar',
                        cantidad,
                        horasMantenimiento: indefinido ? null : horas,
                        indefinido: indefinido,
                      );

                      if (!mounted) return;
                      Navigator.pop(outerContext);
                      ScaffoldMessenger.of(outerContext).showSnackBar(
                        SnackBar(
                          content: Text(resultado
                              ? '$cantidad unidad(es) en mantenimiento'
                              : 'Error al actualizar'),
                          backgroundColor:
                              resultado ? Colors.orange : Colors.red,
                        ),
                      );
                    },
                    icon: const Icon(Icons.build),
                    label: const Text('Poner en Mantenimiento'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
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
    final cantidadController = TextEditingController(text: '1');
    final precioAlquilerController = TextEditingController();
    final precioVentaController = TextEditingController();
    final outerContext = context;

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
                    DropdownMenuItem(
                        value: 'pantalon', child: Text('Pantalón')),
                    DropdownMenuItem(value: 'camisa', child: Text('Camisa')),
                    DropdownMenuItem(value: 'zapato', child: Text('Zapato')),
                    DropdownMenuItem(
                        value: 'extra', child: Text('Extra (Corbatas, etc.)')),
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
                  controller: cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad *',
                    border: OutlineInputBorder(),
                    helperText: 'Unidades totales en inventario',
                  ),
                  keyboardType: TextInputType.number,
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
                    cantidadController.text.isEmpty ||
                    precioAlquilerController.text.isEmpty ||
                    precioVentaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Complete los campos obligatorios')),
                  );
                  return;
                }

                final cantidad = int.tryParse(cantidadController.text);
                if (cantidad == null || cantidad < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('La cantidad debe ser al menos 1')),
                  );
                  return;
                }

                final nuevoArticulo = Articulo(
                  codigo: codigoController.text,
                  nombre: nombreController.text,
                  tipo: tipo,
                  talla: tallaController.text.isEmpty
                      ? null
                      : tallaController.text,
                  color: colorController.text.isEmpty
                      ? null
                      : colorController.text,
                  cantidad: cantidad,
                  cantidadDisponible: cantidad,
                  precioAlquiler: double.parse(precioAlquilerController.text),
                  precioVenta: double.parse(precioVentaController.text),
                  estado: 'disponible',
                );

                final provider = Provider.of<InventarioProvider>(outerContext,
                    listen: false);
                final resultado = await provider.crearArticulo(nuevoArticulo);

                if (!mounted) return;
                Navigator.pop(outerContext);
                ScaffoldMessenger.of(outerContext).showSnackBar(
                  SnackBar(
                    content: Text(resultado['success']
                        ? 'Artículo creado exitosamente'
                        : 'Error: ${resultado['error']}'),
                    backgroundColor:
                        resultado['success'] ? Colors.green : Colors.red,
                  ),
                );
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
                  const SnackBar(
                      content: Text('Complete los campos obligatorios')),
                );
                return;
              }

              final articuloActualizado = Articulo(
                id: articulo.id,
                codigo: articulo.codigo,
                nombre: nombreController.text,
                tipo: articulo.tipo,
                talla:
                    tallaController.text.isEmpty ? null : tallaController.text,
                color:
                    colorController.text.isEmpty ? null : colorController.text,
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
        content:
            Text('¿Está seguro de eliminar el artículo ${articulo.nombre}?'),
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

      if (!mounted) return;
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

  Future<void> _mostrarDialogoCrearTraje() async {
    // Use a dedicated dialog widget that owns its controllers to avoid lifecycle
    // issues when cancelling the dialog.
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => const _CrearTrajeDialog(),
    );

    if (result != null &&
        result['articulos'] != null &&
        (result['articulos'] as List).isNotEmpty) {
      final provider = Provider.of<InventarioProvider>(context, listen: false);
      final success = await provider.crearTraje(
        result['nombre'] as String,
        result['descripcion'] as String,
        (result['articulos'] as List<Articulo>).map((a) => a.id!).toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Traje creado exitosamente' : 'Error al crear traje'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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

// Dialog widget that owns its TextEditingControllers and selection state
IconData _iconoTipoGlobal(String tipo) {
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

class _CrearTrajeDialog extends StatefulWidget {
  const _CrearTrajeDialog();

  @override
  State<_CrearTrajeDialog> createState() => __CrearTrajeDialogState();
}

class __CrearTrajeDialogState extends State<_CrearTrajeDialog> {
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  List<Articulo> articulosSeleccionados = [];

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventarioProvider>(context, listen: false);
    final articulosDisponibles =
        provider.articulos.where((a) => a.cantidadDisponible > 0).toList();

    return AlertDialog(
      title: const Text('Crear Nuevo Traje'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Traje',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checkroom),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final seleccionados = await showDialog<List<Articulo>>(
                  context: context,
                  builder: (context) => _DialogoSeleccionarArticulosTraje(
                    articulosDisponibles: articulosDisponibles,
                    articulosSeleccionados: articulosSeleccionados,
                  ),
                );
                if (seleccionados != null) {
                  setState(() {
                    articulosSeleccionados = seleccionados;
                  });
                }
              },
              icon: const Icon(Icons.add_circle),
              label: Text(articulosSeleccionados.isEmpty
                  ? 'Seleccionar Artículos'
                  : '${articulosSeleccionados.length} artículos'),
            ),
            if (articulosSeleccionados.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: articulosSeleccionados.length,
                  itemBuilder: (context, index) {
                    final art = articulosSeleccionados[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(_iconoTipoGlobal(art.tipo), size: 20),
                      title: Text(art.nombre,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text('${art.tipo} - ${art.talla}',
                          style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: articulosSeleccionados.isEmpty
              ? null
              : () {
                  if (nombreController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingrese nombre del traje')),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'nombre': nombreController.text,
                    'descripcion': descripcionController.text,
                    'articulos': articulosSeleccionados,
                  });
                },
          child: const Text('Crear Traje'),
        ),
      ],
    );
  }
}

// Widget diálogo para seleccionar artículos del traje
class _DialogoSeleccionarArticulosTraje extends StatefulWidget {
  final List<Articulo> articulosDisponibles;
  final List<Articulo> articulosSeleccionados;

  const _DialogoSeleccionarArticulosTraje({
    required this.articulosDisponibles,
    required this.articulosSeleccionados,
  });

  @override
  State<_DialogoSeleccionarArticulosTraje> createState() =>
      __DialogoSeleccionarArticulosTrajeState();
}

class __DialogoSeleccionarArticulosTrajeState
    extends State<_DialogoSeleccionarArticulosTraje> {
  late List<Articulo> _seleccionados;
  final _searchController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _seleccionados = List.from(widget.articulosSeleccionados);
  }

  @override
  Widget build(BuildContext context) {
    final articulosFiltrados = widget.articulosDisponibles.where((a) {
      final query = _filtro.toLowerCase();
      return a.nombre.toLowerCase().contains(query) ||
          a.codigo.toLowerCase().contains(query) ||
          a.tipo.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      title: const Text('Seleccionar Artículos para el Traje'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
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
                itemCount: articulosFiltrados.length,
                itemBuilder: (context, index) {
                  final articulo = articulosFiltrados[index];
                  final seleccionado =
                      _seleccionados.any((a) => a.id == articulo.id);

                  return CheckboxListTile(
                    value: seleccionado,
                    title: Text(articulo.nombre),
                    subtitle: Text(
                      '${articulo.tipo} - ${articulo.talla} - ${articulo.color}\nStock: ${articulo.cantidadDisponible}',
                    ),
                    secondary: Icon(_getIconoTipo(articulo.tipo)),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _seleccionados.add(articulo);
                        } else {
                          _seleccionados
                              .removeWhere((a) => a.id == articulo.id);
                        }
                      });
                    },
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
          onPressed: () => Navigator.pop(context, _seleccionados),
          icon: const Icon(Icons.check),
          label: Text('Aceptar (${_seleccionados.length})'),
        ),
      ],
    );
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
    _searchController.dispose();
    super.dispose();
  }
}
