import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/citas_provider.dart';
import '../../providers/clientes_provider.dart';
import '../../models/cita.dart';
import '../../models/cliente.dart';
import '../../utils/validators.dart';

class CrearCitaScreen extends StatefulWidget {
  const CrearCitaScreen({super.key});

  @override
  State<CrearCitaScreen> createState() => _CrearCitaScreenState();
}

class _CrearCitaScreenState extends State<CrearCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _descripcionController = TextEditingController();

  Cliente? _clienteExistente;
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _horaSeleccionada = TimeOfDay.now();
  String _tipoSeleccionado = 'alquiler';
  bool _buscandoCliente = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final clientesProvider =
        Provider.of<ClientesProvider>(context, listen: false);
    await clientesProvider.cargarClientes();
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cita'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccionCliente(),
              const SizedBox(height: 20),
              _buildSeccionCita(),
              const SizedBox(height: 20),
              _buildSeccionDescripcion(),
              const SizedBox(height: 32),
              _buildBotonGuardar(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionCliente() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Datos del Cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _dniController,
              decoration: InputDecoration(
                labelText: 'DNI',
                hintText: '8 dígitos',
                prefixIcon: const Icon(Icons.badge),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _buscandoCliente
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _buscarClientePorDni,
                      ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              validator: Validators.validateDni,
              onChanged: (value) {
                if (value.length == 8 && RegExp(r'^\d{8}$').hasMatch(value)) {
                  _buscarClientePorDni();
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: Validators.validateNombre,
              readOnly: _clienteExistente != null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: '9 dígitos',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 9,
              validator: Validators.validateTelefono,
              readOnly: _clienteExistente != null,
            ),
            if (_clienteExistente != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Cliente encontrado',
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _limpiarCliente,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Limpiar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionCita() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Detalles de la Cita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de Cita',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'alquiler',
                  child: Text('Alquiler'),
                ),
                DropdownMenuItem(
                  value: 'prueba',
                  child: Text('Prueba de Terno'),
                ),
                DropdownMenuItem(
                  value: 'devolucion',
                  child: Text('Devolución'),
                ),
                DropdownMenuItem(
                  value: 'otro',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tipoSeleccionado = value);
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _seleccionarFecha,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(_fechaSeleccionada),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _seleccionarHora,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Hora',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _horaSeleccionada.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionDescripcion() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notes, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Observaciones',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción / Notas (Opcional)',
                hintText: 'Ingrese detalles adicionales de la cita',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _guardarCita,
        icon: const Icon(Icons.save),
        label: const Text(
          'Guardar Cita',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _buscarClientePorDni() async {
    if (_dniController.text.isEmpty || _dniController.text.length != 8) {
      return;
    }

    setState(() => _buscandoCliente = true);

    final clientesProvider =
        Provider.of<ClientesProvider>(context, listen: false);
    final cliente = clientesProvider.clientes.firstWhere(
      (c) => c.dni == _dniController.text && !c.enPapelera,
      orElse: () => Cliente(nombre: '', dni: '', telefono: ''),
    );

    setState(() {
      _buscandoCliente = false;
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

  void _limpiarCliente() {
    setState(() {
      _clienteExistente = null;
      _dniController.clear();
      _nombreController.clear();
      _telefonoController.clear();
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (hora != null) {
      setState(() => _horaSeleccionada = hora);
    }
  }

  Future<void> _guardarCita() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos correctamente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.event_available, color: Colors.blue),
            SizedBox(width: 8),
            Text('Confirmar Cita'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmacionRow('Cliente:', _nombreController.text),
            _buildConfirmacionRow('DNI:', _dniController.text),
            _buildConfirmacionRow('Teléfono:', _telefonoController.text),
            const Divider(height: 20),
            _buildConfirmacionRow('Tipo:', _getTipoText(_tipoSeleccionado)),
            _buildConfirmacionRow(
              'Fecha:',
              DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
            ),
            _buildConfirmacionRow('Hora:', _horaSeleccionada.format(context)),
            if (_descripcionController.text.isNotEmpty) ...[
              const Divider(height: 20),
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_descripcionController.text),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: const Text('Confirmar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Crear o buscar cliente
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
      if (!resultado['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear cliente: ${resultado['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      clienteId = resultado['data']['id'];
    }

    // Crear la cita
    final fechaHora = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      _horaSeleccionada.hour,
      _horaSeleccionada.minute,
    );

    final nuevaCita = Cita(
      clienteId: clienteId,
      fechaHora: fechaHora,
      tipo: _tipoSeleccionado,
      descripcion: _descripcionController.text.isEmpty
          ? null
          : _descripcionController.text,
    );

    final citasProvider = Provider.of<CitasProvider>(context, listen: false);
    final resultado = await citasProvider.crearCita(nuevaCita);

    if (mounted) {
      if (resultado['success']) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cita creada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${resultado['message'] ?? 'Error al crear cita'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConfirmacionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getTipoText(String tipo) {
    switch (tipo) {
      case 'alquiler':
        return 'Alquiler';
      case 'prueba':
        return 'Prueba de Terno';
      case 'devolucion':
        return 'Devolución';
      case 'otro':
        return 'Otro';
      default:
        return tipo;
    }
  }
}
