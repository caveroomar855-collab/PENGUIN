import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/config_provider.dart';
import 'providers/clientes_provider.dart';
import 'providers/alquileres_provider.dart';
import 'providers/ventas_provider.dart';
import 'providers/inventario_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => ClientesProvider()),
        ChangeNotifierProvider(create: (_) => AlquileresProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Penguin Ternos',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightBlue,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.lightBlue,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            ),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
