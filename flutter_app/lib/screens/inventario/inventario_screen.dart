import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final String _filtroEstado =
      'todos'; // todos, disponible, alquilado, mantenimiento

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
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar artículo',
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

              final articulos = provider.articulos.where((a) {
                if (_searchQuery.isEmpty) return true;
                return a.nombre.toLowerCase().contains(_searchQuery) ||
                    a.tipo.toLowerCase().contains(_searchQuery) ||
                    (a.talla?.toLowerCase().contains(_searchQuery) ?? false);
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

              return RefreshIndicator(
                onRefresh: _cargarDatos,
                child: ListView.builder(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  itemCount: articulos.length,
                  itemBuilder: (context, index) {
                    final articulo = articulos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      child: ListTile(
                        leading: FaIcon(_getIconoTipo(articulo.tipo),
                            size: 24, color: _getEstadoColor(articulo.estado)),
                        title: Text(articulo.nombre,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        /*subtitle: Text(
                            'Stock: ${articulo.cantidadDisponible}/${articulo.cantidad}'),*/

                        subtitle: Text(
                          // Usamos una condición ternaria: Si tiene talla, la mostramos con un separador
                          '${articulo.talla != null && articulo.talla!.isNotEmpty ? "Talla: ${articulo.talla}  •  " : ""}Stock: ${articulo.cantidadDisponible}/${articulo.cantidad}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'ver',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('Ver'),
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
                                  Icon(Icons.build,
                                      size: 20, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Gestionar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar',
                                      style: TextStyle(color: Colors.red)),
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
                  },
                ),
              );
            },
          ),
        ),
      ],
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
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 80),
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
            if (value == 'editar informacion') {
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
                  '${articulo.nombre} - Stock: ${articulo.cantidadDisponible}/${articulo.cantidad}'),
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
                          }),
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
              // Código removed per client request
              _buildDetalleRow('Tipo:', articulo.tipo.toUpperCase()),
              if (articulo.talla != null)
                _buildDetalleRow('Talla:', articulo.talla!),
              // Color removed from model
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
          // Always allow opening the maintenance dialog so the user can
          // put units into maintenance or remove them manually.
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

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final hasQuitar = articulo.cantidadMantenimiento > 0;
          final hasPoner = articulo.cantidadDisponible > 0;

          return AlertDialog(
            title: const Text('Gestionar Articulo'),
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
                  Text('Alquilados: ${articulo.cantidadAlquilada}',
                      style: const TextStyle(color: Colors.blue)),
                  const Divider(height: 24),
                  if (hasQuitar || hasPoner) ...[
                    const Text('Gestionar Unidades en Mantenimiento',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // (Removed single-field 'quitar' box — management uses the
                    // unified 'Gestionar Unidades en Mantenimiento' flow below.)

                    // Poner unidades en mantenimiento (si aplica)
                    if (hasPoner) ...[
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
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (hasQuitar || hasPoner)
                    Row(
                      children: [
                        if (hasQuitar)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Confirm intention before removing from maintenance
                                final cantidadToRemove = (cantidad <= 0)
                                    ? articulo.cantidadMantenimiento
                                    : cantidad;
                                final confirm = await showDialog<bool>(
                                      context: outerContext,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirmar'),
                                        content: Text(
                                            '¿Estás seguro que quieres quitar $cantidadToRemove unidad(es) de mantenimiento de "${articulo.nombre}" y devolverlas a disponible?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Confirmar'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;

                                if (!confirm) return;

                                final provider =
                                    Provider.of<InventarioProvider>(
                                        outerContext,
                                        listen: false);
                                final resultado =
                                    await provider.gestionarMantenimiento(
                                  articulo.id!,
                                  'quitar',
                                  cantidadToRemove,
                                );

                                if (!mounted) return;
                                Navigator.pop(outerContext);
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  SnackBar(
                                    content: Text(resultado
                                        ? '$cantidadToRemove unidad(es) disponible(s) nuevamente'
                                        : 'Error al actualizar'),
                                    backgroundColor:
                                        resultado ? Colors.green : Colors.red,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Quitar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                        if (hasQuitar && hasPoner) const SizedBox(width: 12),
                        if (hasPoner)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (cantidad <= 0 ||
                                    cantidad > articulo.cantidadDisponible) {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text('Cantidad inválida')),
                                  );
                                  return;
                                }

                                // Confirm intention before putting into maintenance
                                final confirm = await showDialog<bool>(
                                      context: outerContext,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Confirmar'),
                                        content: Text(
                                            '¿Estás seguro que quieres poner $cantidad unidad(es) de "${articulo.nombre}" en mantenimiento${indefinido ? ' (indefinido)' : ' por $horas horas'}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Confirmar'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;

                                if (!confirm) return;

                                final provider =
                                    Provider.of<InventarioProvider>(
                                        outerContext,
                                        listen: false);
                                final resultado =
                                    await provider.gestionarMantenimiento(
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
                              label: const Text('Poner'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  const SizedBox(height: 8),
                  const Text('Ajustar Stock',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('stock_adjust_amount'),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: const OutlineInputBorder(),
                      helperText: 'Máximo: ${articulo.cantidad}',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setDialogState(() => cantidad = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (cantidad <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                    content: Text('Cantidad inválida')),
                              );
                              return;
                            }

                            // If removing equal or more than total, confirm deletion
                            if (cantidad >= articulo.cantidad) {
                              final confirm = await showDialog<bool>(
                                    context: outerContext,
                                    builder: (ctx) => AlertDialog(
                                      title:
                                          const Text('Confirmar eliminación'),
                                      content: Text(
                                          'Vas a quitar $cantidad unidad(es). El artículo "${articulo.nombre}" quedará con 0 unidades y se eliminará. ¿Continuar?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (!confirm) return;

                              final provider = Provider.of<InventarioProvider>(
                                  outerContext,
                                  listen: false);
                              final deleted =
                                  await provider.eliminarArticulo(articulo.id!);
                              if (!mounted) return;
                              Navigator.pop(outerContext);
                              ScaffoldMessenger.of(outerContext).showSnackBar(
                                SnackBar(
                                  content: Text(deleted
                                      ? 'Artículo eliminado'
                                      : 'Error eliminando'),
                                  backgroundColor:
                                      deleted ? Colors.green : Colors.red,
                                ),
                              );
                              return;
                            }

                            // Otherwise just decrease cantidad
                            final nuevaCantidad = articulo.cantidad - cantidad;
                            final articuloActualizado = Articulo(
                              id: articulo.id,
                              nombre: articulo.nombre,
                              tipo: articulo.tipo,
                              talla: articulo.talla,
                              precioAlquiler: articulo.precioAlquiler,
                              precioVenta: articulo.precioVenta,
                              estado: articulo.estado,
                              fechaDisponible: articulo.fechaDisponible,
                              cantidad: nuevaCantidad,
                            );

                            final provider = Provider.of<InventarioProvider>(
                                outerContext,
                                listen: false);
                            final resultado = await provider.actualizarArticulo(
                                articulo.id!, articuloActualizado);
                            if (!mounted) return;
                            Navigator.pop(outerContext);
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              SnackBar(
                                content: Text(resultado
                                    ? 'Cantidad actualizada'
                                    : 'Error al actualizar'),
                                backgroundColor:
                                    resultado ? Colors.green : Colors.red,
                              ),
                            );
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Quitar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (cantidad <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                    content: Text('Cantidad inválida')),
                              );
                              return;
                            }

                            final nuevaCantidad = articulo.cantidad + cantidad;
                            final articuloActualizado = Articulo(
                              id: articulo.id,
                              nombre: articulo.nombre,
                              tipo: articulo.tipo,
                              talla: articulo.talla,
                              precioAlquiler: articulo.precioAlquiler,
                              precioVenta: articulo.precioVenta,
                              estado: articulo.estado,
                              fechaDisponible: articulo.fechaDisponible,
                              cantidad: nuevaCantidad,
                            );

                            final provider = Provider.of<InventarioProvider>(
                                outerContext,
                                listen: false);
                            final resultado = await provider.actualizarArticulo(
                                articulo.id!, articuloActualizado);
                            if (!mounted) return;
                            Navigator.pop(outerContext);
                            ScaffoldMessenger.of(outerContext).showSnackBar(
                              SnackBar(
                                content: Text(resultado
                                    ? 'Cantidad actualizada'
                                    : 'Error al actualizar'),
                                backgroundColor:
                                    resultado ? Colors.green : Colors.red,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoCrearArticulo() async {
    final nombreController = TextEditingController();
    String tipo = 'saco';
    final tallaController = TextEditingController();
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
                // Código input removed per client request
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
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
                if (nombreController.text.isEmpty ||
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
                  nombre: nombreController.text,
                  tipo: tipo,
                  talla: tallaController.text.isEmpty
                      ? null
                      : tallaController.text,
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
                nombre: nombreController.text,
                tipo: articulo.tipo,
                talla:
                    tallaController.text.isEmpty ? null : tallaController.text,
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
    // TODO: implementar edición de traje (editar nombre/descripcion/artículos)
    // Por ahora mostramos un diálogo simple con la información básica.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar traje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${traje.nombre}'),
            const SizedBox(height: 8),
            Text('Descripción: ${traje.descripcion ?? '-'}'),
            const SizedBox(height: 8),
            Text(
                'Artículos: ${traje.articulos.map((a) => a.nombre).join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cerrar')),
        ],
      ),
    );
    // no hay acción adicional por ahora
  }

  Future<void> _confirmarEliminarTraje(Traje traje) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Traje'),
        content: Text(
            '¿Deseas eliminar el traje "${traje.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar == true) {
      final provider = Provider.of<InventarioProvider>(context, listen: false);
      final resultado = await provider.eliminarTraje(traje.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado
              ? 'Traje eliminado exitosamente'
              : 'Error al eliminar traje'),
          backgroundColor: resultado ? Colors.green : Colors.red,
        ),
      );
    }
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
        //return Icons.checkroom;
        return FontAwesomeIcons.userTie;
      case 'chaleco':
        return FontAwesomeIcons.vest;
      case 'pantalon':
        //return Icons.boy;
        return FontAwesomeIcons.person;
      case 'camisa':
        return FontAwesomeIcons.shirt;
      case 'zapato':
        return FontAwesomeIcons.shoePrints;
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
      //return Icons.checkroom;
      return FontAwesomeIcons.userTie;
    case 'chaleco':
      return FontAwesomeIcons.vest;
    case 'pantalon':
      //return Icons.boy;
      return FontAwesomeIcons.person;
    case 'camisa':
      return FontAwesomeIcons.shirt;
    case 'zapato':
      return FontAwesomeIcons.shoePrints;
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
          a.tipo.toLowerCase().contains(query) ||
          (a.talla?.toLowerCase().contains(query) ?? false);
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
                        '${articulo.tipo} - ${articulo.talla} - ${articulo.nombre}\nStock: ${articulo.cantidadDisponible}'),
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
