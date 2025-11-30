import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/clientes_provider.dart';
import '../../models/cliente.dart';
import '../../utils/validators.dart';
import '../../utils/whatsapp_helper.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarPapelera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarClientes();
    });
  }

  Future<void> _cargarClientes() async {
    final provider = Provider.of<ClientesProvider>(context, listen: false);
    await provider.cargarClientes();
  }

  List<Cliente> _filtrarClientes(List<Cliente> clientes) {
    final query = _searchController.text.toLowerCase();
    return clientes.where((cliente) {
      final coincide = cliente.dni.toLowerCase().contains(query) ||
          cliente.nombre.toLowerCase().contains(query) ||
          cliente.telefono.toLowerCase().contains(query);

      return _mostrarPapelera
          ? cliente.enPapelera
          : !cliente.enPapelera && coincide;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_mostrarPapelera ? 'Papelera' : 'Clientes'),
        actions: [
          IconButton(
            icon: Icon(_mostrarPapelera ? Icons.arrow_back : Icons.delete),
            onPressed: () {
              setState(() => _mostrarPapelera = !_mostrarPapelera);
            },
            tooltip: _mostrarPapelera ? 'Volver' : 'Ver Papelera',
          ),
        ],
      ),
      body: Consumer<ClientesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.clientes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final clientesFiltrados = _filtrarClientes(provider.clientes);

          return Column(
            children: [
              if (!_mostrarPapelera)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por DNI, nombre o teléfono',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchController.clear());
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _cargarClientes,
                  child: clientesFiltrados.isEmpty
                      ? Center(
                          child: Text(
                            _mostrarPapelera
                                ? 'No hay clientes en la papelera'
                                : 'No hay clientes',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: clientesFiltrados.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final cliente = clientesFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    cliente.nombre[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  cliente.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DNI: ${cliente.dni}'),
                                    Text('Tel: ${cliente.telefono}'),
                                  ],
                                ),
                                trailing: _mostrarPapelera
                                    ? IconButton(
                                        icon: const Icon(Icons.restore,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _restaurarCliente(cliente),
                                        tooltip: 'Restaurar',
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize
                                            .min, // Vital para que no ocupe toda la fila
                                        children: [
                                          // --- BOTÓN DE WHATSAPP ---
                                          IconButton(
                                            icon: const Icon(Icons.message,
                                                color: Colors.green),
                                            tooltip: 'Contactar por WhatsApp',
                                            onPressed: () {
                                              WhatsappHelper.enviarRecordatorio(
                                                context: context,
                                                telefono: cliente.telefono,
                                                nombreCliente: cliente.nombre,
                                                fechaVencimiento: '',
                                                esRecordatorio:
                                                    false, // false = Mensaje de contacto general
                                              );
                                            },
                                          ),
                                          // -------------------------

                                          // TU MENÚ DE OPCIONES EXISTENTE
                                          PopupMenuButton(
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'editar',
                                                child: Row(children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('Editar')
                                                ]),
                                              ),
                                              const PopupMenuItem(
                                                value: 'eliminar',
                                                child: Row(children: [
                                                  Icon(Icons.delete,
                                                      size: 20,
                                                      color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Eliminar',
                                                      style: TextStyle(
                                                          color: Colors.red))
                                                ]),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              if (value == 'editar') {
                                                _mostrarDialogoEditar(cliente);
                                              } else if (value == 'eliminar') {
                                                _confirmarEliminar(cliente);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _mostrarPapelera
          ? null
          : FloatingActionButton(
              onPressed: _mostrarDialogoCrear,
              child: const Icon(Icons.add),
            ),
    );
  }

  void _mostrarDialogoCrear() {
    final formKey = GlobalKey<FormState>();
    final dniController = TextEditingController();
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final emailController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dniController,
                  decoration: const InputDecoration(
                    labelText: 'DNI *',
                    border: OutlineInputBorder(),
                    helperText: '8 dígitos',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  validator: Validators.validateDni,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.validateNombre,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder(),
                    helperText: '9 dígitos, inicia con 9',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  validator: Validators.validateTelefono,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final provider =
                  Provider.of<ClientesProvider>(context, listen: false);
              final nuevoCliente = Cliente(
                dni: dniController.text,
                nombre: nombreController.text,
                telefono: telefonoController.text,
                email:
                    emailController.text.isEmpty ? null : emailController.text,
                descripcion: descripcionController.text.isEmpty
                    ? null
                    : descripcionController.text,
              );

              final resultado = await provider.crearCliente(nuevoCliente);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resultado['success']
                        ? 'Cliente creado exitosamente'
                        : 'Error al crear cliente'),
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
    );
  }

  void _mostrarDialogoEditar(Cliente cliente) {
    final formKey = GlobalKey<FormState>();
    final dniController = TextEditingController(text: cliente.dni);
    final nombreController = TextEditingController(text: cliente.nombre);
    final telefonoController = TextEditingController(text: cliente.telefono);
    final emailController = TextEditingController(text: cliente.email ?? '');
    final descripcionController =
        TextEditingController(text: cliente.descripcion ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dniController,
                  decoration: const InputDecoration(
                    labelText: 'DNI *',
                    border: OutlineInputBorder(),
                    helperText: '8 dígitos',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  validator: Validators.validateDni,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: Validators.validateNombre,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder(),
                    helperText: '9 dígitos, inicia con 9',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  validator: Validators.validateTelefono,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final provider =
                  Provider.of<ClientesProvider>(context, listen: false);
              final clienteActualizado = Cliente(
                id: cliente.id,
                dni: dniController.text,
                nombre: nombreController.text,
                telefono: telefonoController.text,
                email:
                    emailController.text.isEmpty ? null : emailController.text,
                descripcion: descripcionController.text.isEmpty
                    ? null
                    : descripcionController.text,
              );

              final resultado = await provider.actualizarCliente(
                  cliente.id!, clienteActualizado);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resultado
                        ? 'Cliente actualizado exitosamente'
                        : 'Error al actualizar cliente'),
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

  void _confirmarEliminar(Cliente cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Enviar a papelera al cliente ${cliente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider =
                  Provider.of<ClientesProvider>(context, listen: false);
              final resultado = await provider.enviarAPapelera(cliente.id!);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(resultado['success']
                        ? 'Cliente enviado a papelera'
                        : 'Error al eliminar cliente'),
                    backgroundColor:
                        resultado['success'] ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _restaurarCliente(Cliente cliente) async {
    final provider = Provider.of<ClientesProvider>(context, listen: false);
    final resultado = await provider.restaurarDePapelera(cliente.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado
              ? 'Cliente restaurado exitosamente'
              : 'Error al restaurar cliente'),
          backgroundColor: resultado ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
