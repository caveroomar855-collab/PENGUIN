import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'inicio/inicio_screen.dart';
import 'clientes/clientes_screen.dart';
import 'reportes/reportes_screen.dart';
import 'configuracion/configuracion_screen.dart';
import '../providers/config_provider.dart';
import '../providers/clientes_provider.dart';
import '../providers/alquileres_provider.dart';
import '../providers/ventas_provider.dart';
import '../providers/inventario_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InicioScreen(),
    const ClientesScreen(),
    const ReportesScreen(),
    const ConfiguracionScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    final clientesProvider =
        Provider.of<ClientesProvider>(context, listen: false);
    final alquileresProvider =
        Provider.of<AlquileresProvider>(context, listen: false);
    final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
    final inventarioProvider =
        Provider.of<InventarioProvider>(context, listen: false);

    await configProvider.cargarConfiguracion();
    await clientesProvider.cargarClientes();
    await alquileresProvider.cargarActivos();
    await ventasProvider.cargarVentas();
    await inventarioProvider.cargarArticulos();
    await inventarioProvider.cargarTrajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
