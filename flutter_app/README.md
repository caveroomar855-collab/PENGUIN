# Penguin Ternos - Aplicación Flutter

Sistema completo de gestión de alquiler y venta de ternos.

## Estructura del Proyecto

```
flutter_app/
├── lib/
│   ├── config/
│   │   └── api_config.dart           # Configuración de API
│   ├── models/
│   │   ├── cliente.dart              # Modelo de Cliente
│   │   ├── articulo.dart             # Modelo de Artículo
│   │   ├── traje.dart                # Modelo de Traje
│   │   ├── alquiler.dart             # Modelo de Alquiler
│   │   ├── venta.dart                # Modelo de Venta
│   │   └── configuracion.dart        # Modelo de Configuración
│   ├── providers/
│   │   ├── theme_provider.dart       # Gestión de tema claro/oscuro
│   │   ├── config_provider.dart      # Gestión de configuración
│   │   ├── clientes_provider.dart    # Gestión de clientes
│   │   ├── alquileres_provider.dart  # Gestión de alquileres
│   │   ├── ventas_provider.dart      # Gestión de ventas
│   │   └── inventario_provider.dart  # Gestión de inventario
│   ├── screens/
│   │   ├── splash_screen.dart        # Pantalla de inicio
│   │   ├── main_screen.dart          # Navegación principal
│   │   ├── inicio/
│   │   │   └── inicio_screen.dart    # Pantalla de inicio
│   │   ├── clientes/
│   │   │   └── clientes_screen.dart  # Gestión de clientes
│   │   ├── alquileres/
│   │   │   └── alquileres_screen.dart
│   │   ├── ventas/
│   │   │   └── ventas_screen.dart
│   │   ├── inventario/
│   │   │   └── inventario_screen.dart
│   │   ├── reportes/
│   │   │   └── reportes_screen.dart
│   │   └── configuracion/
│   │       └── configuracion_screen.dart
│   └── main.dart
└── pubspec.yaml
```

## Instalación

### Requisitos previos
- Flutter SDK (versión 3.0 o superior)
- Android Studio / VS Code
- Dispositivo Android o emulador

### Pasos de instalación

1. **Navegar a la carpeta del proyecto:**
   ```bash
   cd c:\a\flutter_app
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configurar la URL de la API:**
   
   Edita `lib/config/api_config.dart` y cambia la URL base:
   
   - Si usas el emulador de Android: `http://10.0.2.2:3000/api`
   - Si usas un dispositivo físico: `http://TU_IP_LOCAL:3000/api` (ejemplo: `http://192.168.1.100:3000/api`)

4. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

## Funcionalidades Implementadas

### ✅ Completadas (Base)

- **Splash Screen** con logo de la tienda
- **Navegación principal** con 4 apartados (Inicio, Clientes, Reportes, Configuración)
- **Modelos de datos** para todas las entidades
- **Providers** para gestión de estado
- **Pantalla de Inicio** con resumen del día
- **Pantalla de Clientes** con búsqueda
- **Pantalla de Configuración** completa

### 🚧 En Desarrollo

Las siguientes pantallas tienen su estructura base pero requieren implementación completa:

- **Módulo de Alquileres:**
  - Crear alquiler
  - Alquileres activos
  - Historial
  - Marcar devolución con estados (Completo, Dañado, Perdido)
  - Sistema de moras

- **Módulo de Ventas:**
  - Crear venta
  - Historial de ventas
  - Devoluciones (máximo 3 días)

- **Módulo de Inventario:**
  - Vista de artículos por estado
  - Vista de trajes
  - Gestión de mantenimiento
  - Crear/editar artículos y trajes

- **Módulo de Reportes:**
  - Generación de PDF
  - Reportes por rango de fechas
  - Reportes de alquileres y ventas

- **Módulo de Citas:**
  - Crear citas
  - Gestión de citas pendientes

## Dependencias Principales

```yaml
dependencies:
  provider: ^6.1.1              # Gestión de estado
  http: ^1.1.2                  # Peticiones HTTP
  shared_preferences: ^2.2.2    # Almacenamiento local
  pdf: ^3.10.7                  # Generación de PDF
  printing: ^5.11.1             # Impresión de PDF
  intl: ^0.18.1                 # Internacionalización y formato
  google_fonts: ^6.1.0          # Fuentes personalizadas
```

## Características del Sistema

### Gestión de Clientes
- Crear cliente con DNI único
- Búsqueda por DNI o nombre
- Editar información del cliente
- Papelera de clientes (no se puede eliminar si tiene alquileres activos)
- Autocompletado de datos por DNI

### Gestión de Alquileres
- Crear alquiler con artículos individuales o trajes
- Fechas de inicio y fin
- Monto de alquiler personalizable
- Garantía configurable
- Devolución con estados de artículos
- Sistema de moras automático
- Retención de garantía

### Gestión de Ventas
- Venta de artículos
- Devolución hasta 3 días después
- Cálculo automático de totales

### Gestión de Inventario
- Estados: Disponible, Alquilado, Mantenimiento, Vendido, Perdido
- Mantenimiento automático (24h completo, 72h dañado)
- Mantenimiento manual personalizable
- Agrupación de artículos en trajes

### Configuración
- Nombre del empleado
- Tema claro/oscuro
- Garantía por defecto
- Mora diaria
- Días máximos de mora

## Notas Importantes

1. **Backend Local:** Asegúrate de que el backend Node.js esté corriendo antes de usar la app
2. **Supabase:** Configura tu proyecto de Supabase y crea las tablas según el esquema
3. **Red Local:** El dispositivo/emulador debe estar en la misma red que el servidor
4. **Permisos:** La app puede requerir permisos de red e impresión

## Próximos Pasos para Completar

1. Implementar formularios completos de creación de alquileres y ventas
2. Añadir selector de artículos con búsqueda
3. Implementar vista de trajes con selección de artículos
4. Crear sistema de devoluciones con estados
5. Implementar generación de reportes PDF
6. Añadir módulo de citas
7. Mejorar validaciones y manejo de errores
8. Añadir animaciones y transiciones
9. Implementar caché local para mejor rendimiento
10. Añadir tests unitarios y de integración

## Recursos

- [Documentación de Flutter](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)
- [PDF Package](https://pub.dev/packages/pdf)

## Soporte

Para reportar problemas o solicitar ayuda, contacta al equipo de desarrollo.
