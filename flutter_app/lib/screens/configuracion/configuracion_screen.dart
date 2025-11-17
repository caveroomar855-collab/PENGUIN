import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/config_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/configuracion.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _garantiaController;
  late TextEditingController _moraController;
  late TextEditingController _diasMoraController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _garantiaController = TextEditingController();
    _moraController = TextEditingController();
    _diasMoraController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarConfiguracion();
    });
  }

  void _cargarConfiguracion() {
    final config =
        Provider.of<ConfigProvider>(context, listen: false).configuracion;
    if (config != null) {
      _nombreController.text = config.nombreEmpleado;
      _garantiaController.text = config.garantiaDefault.toString();
      _moraController.text = config.moraDiaria.toString();
      _diasMoraController.text = config.diasMaximosMora.toString();
    }
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final config = Configuracion(
      nombreEmpleado: _nombreController.text,
      temaOscuro: themeProvider.isDarkMode,
      garantiaDefault: double.parse(_garantiaController.text),
      moraDiaria: double.parse(_moraController.text),
      diasMaximosMora: int.parse(_diasMoraController.text),
    );

    final success = await configProvider.actualizarConfiguracion(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Configuración guardada exitosamente'
              : 'Error al guardar la configuración'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context).configuracion;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarConfiguracion,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del empleado
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Empleado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Empleado',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un nombre';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Apariencia
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apariencia',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SwitchListTile(
                        title: const Text('Tema Oscuro'),
                        subtitle:
                            const Text('Cambiar entre tema claro y oscuro'),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Configuración de Alquileres
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Alquileres',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _garantiaController,
                        decoration: const InputDecoration(
                          labelText: 'Garantía por Defecto (S/)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un monto';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _moraController,
                        decoration: const InputDecoration(
                          labelText: 'Mora Diaria (S/)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money_off),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un monto';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diasMoraController,
                        decoration: const InputDecoration(
                          labelText: 'Días Máximos de Mora',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          helperText:
                              'Días después de los cuales se retiene la garantía',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un número';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Por favor ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarConfiguracion,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Configuración'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _garantiaController.dispose();
    _moraController.dispose();
    _diasMoraController.dispose();
    super.dispose();
  }
}
