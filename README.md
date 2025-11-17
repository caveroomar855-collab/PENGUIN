# Penguin Ternos - Sistema de Gestión

Sistema completo de gestión de alquiler y venta de ternos con Flutter y Node.js.

## 📋 Descripción General

Aplicación móvil para gestionar una tienda de alquiler y venta de ternos, incluyendo:
- Gestión de clientes
- Alquiler de artículos con sistema de garantías y moras
- Ventas con devoluciones
- Inventario con estados y mantenimiento
- Reportes y estadísticas
- Configuración personalizable

## 🏗️ Estructura del Proyecto

```
c:\a\
├── backend/                  # Servidor Node.js + Express
│   ├── config/
│   │   └── database.js      # Conexión a Supabase
│   ├── routes/              # Endpoints de API
│   │   ├── clientes.js
│   │   ├── alquileres.js
│   │   ├── ventas.js
│   │   ├── inventario.js
│   │   ├── reportes.js
│   │   └── configuracion.js
│   ├── database/
│   │   └── schema.md        # Esquema de base de datos
│   ├── .env.example         # Ejemplo de variables de entorno
│   ├── package.json
│   └── server.js
│
└── flutter_app/             # Aplicación móvil Flutter
    ├── lib/
    │   ├── config/          # Configuración
    │   ├── models/          # Modelos de datos
    │   ├── providers/       # Gestión de estado
    │   ├── screens/         # Pantallas de la app
    │   └── main.dart
    └── pubspec.yaml
```

## 🚀 Guía de Instalación Rápida

### 1. Configurar Supabase

1. Crear un proyecto en [Supabase](https://supabase.com)
2. Ir al SQL Editor y ejecutar el script en `backend/database/schema.md`
3. Obtener la URL y API Key del proyecto

### 2. Configurar Backend

```bash
# Navegar a la carpeta del backend
cd c:\a\backend

# Instalar dependencias
npm install

# Crear archivo .env (copiar de .env.example)
copy .env.example .env

# Editar .env y agregar tus credenciales de Supabase
notepad .env

# Iniciar el servidor
npm start
```

El servidor se ejecutará en `http://localhost:3000`

### 3. Configurar Flutter

```bash
# Navegar a la carpeta de Flutter
cd c:\a\flutter_app

# Instalar dependencias
flutter pub get

# Configurar la IP de tu servidor en lib/config/api_config.dart
# Para emulador: http://10.0.2.2:3000/api
# Para dispositivo físico: http://TU_IP_LOCAL:3000/api

# Ejecutar la aplicación
flutter run
```

## 📱 Funcionalidades Principales

### Inicio
- 4 botones de acceso rápido (Alquileres, Ventas, Inventario, Citas)
- Resumen del día con alquileres activos
- Citas pendientes
- Ganancias del día (alquileres y ventas)

### Clientes
- Búsqueda por DNI o nombre
- Crear cliente con validación de DNI duplicado
- Editar información del cliente
- Papelera (no se puede eliminar si tiene alquileres activos)
- Autocompletado de datos

### Alquileres
- **Crear alquiler:**
  - Buscar cliente por DNI (autocompletado)
  - Seleccionar artículos individuales o trajes completos
  - Configurar fechas, monto, garantía y método de pago
  - Agregar observaciones

- **Alquileres activos:**
  - Ver todos los alquileres vigentes
  - Indicador de mora si aplica

- **Devolución:**
  - Marcar estado de cada artículo (Completo, Dañado, Perdido)
  - Mantenimiento automático según estado:
    - Completo: 24 horas
    - Dañado: 72 horas
    - Perdido: disminuye inventario
  - Cálculo automático de mora
  - Retención de garantía opcional

### Ventas
- Crear venta similar a alquileres
- Historial de ventas
- Devolución permitida hasta 3 días después
- Al devolver, artículos vuelven a disponible

### Inventario
- **Artículos:**
  - Estados: Disponible, Alquilado, Mantenimiento, Vendido, Perdido
  - Filtrado por estado
  - Crear/editar artículos
  - Gestión manual de mantenimiento

- **Trajes:**
  - Agrupación de 5 artículos (Saco, Camisa, Pantalón, Zapatos, Chaleco)
  - Selección individual de artículos del traje
  - Visualización de disponibilidad

- **Tipos de artículos:**
  - Saco
  - Chaleco
  - Pantalón
  - Camisa
  - Zapato
  - Extra (corbatas, accesorios, etc.)

### Reportes
- Resumen del día en tiempo real
- Reportes de alquileres por rango de fechas con generación de PDF
- Reportes de ventas por rango de fechas con generación de PDF
- Tablas detalladas con artículos incluidos
- Cálculo correcto de ganancias (considerando devoluciones)

### Citas
- Crear citas para alquileres, pruebas, devoluciones u otros
- Auto-búsqueda de clientes por DNI
- Selección de fecha y hora
- Seguimiento de citas pendientes
- Historial completo de citas
- Cambio de estado (completar/cancelar)
- Sistema de notificaciones visual

### Configuración
- Nombre del empleado
- Tema claro/oscuro
- Garantía por defecto
- Mora diaria
- Días máximos de mora antes de retener garantía

## 🔧 Tecnologías Utilizadas

### Backend
- **Node.js** - Entorno de ejecución
- **Express** - Framework web
- **Supabase** - Base de datos PostgreSQL
- **CORS** - Manejo de peticiones cross-origin

### Frontend
- **Flutter** - Framework de UI
- **Provider** - Gestión de estado
- **HTTP** - Peticiones a la API
- **PDF** - Generación de reportes
- **Intl** - Formato de fechas y moneda

## 🗄️ Base de Datos

### Tablas Principales

- **clientes** - Información de clientes
- **articulos** - Artículos individuales
- **trajes** - Agrupaciones de artículos
- **alquileres** - Registros de alquileres
- **alquiler_articulos** - Artículos por alquiler
- **ventas** - Registros de ventas
- **venta_articulos** - Artículos por venta
- **citas** - Citas programadas
- **configuracion** - Configuración del sistema

## ⚙️ Configuración Avanzada

### Cambiar Puerto del Backend

Edita el archivo `.env`:
```
PORT=3000
```

### Configurar IP para Dispositivo Físico

1. Obtén tu IP local:
   ```bash
   ipconfig
   ```
   Busca la IPv4 Address de tu adaptador de red

2. En `flutter_app/lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://TU_IP:3000/api';
   ```

3. Asegúrate de que tu dispositivo esté en la misma red WiFi

## 📝 Notas Importantes

### Lógica de Negocio

- **DNI único:** No se permiten clientes duplicados
- **Alquileres activos:** Bloquean eliminación de clientes
- **Mantenimiento automático:** Se aplica tras devolución según estado
- **Moras:** Se calculan automáticamente después de la fecha de fin
- **Garantía:** Se retiene si hay artículos perdidos o daños graves
- **Devoluciones de ventas:** Máximo 3 días, restaura artículos

### Estado de Artículos

```
DISPONIBLE → puede alquilarse o venderse
ALQUILADO → en poder del cliente
MANTENIMIENTO → no disponible temporalmente
VENDIDO → ya no está en inventario
PERDIDO → no devuelto, descontado del inventario
```

## 🐛 Solución de Problemas

### Error de conexión al backend

1. Verifica que el servidor esté corriendo
2. Confirma la URL en `api_config.dart`
3. Revisa el firewall de Windows
4. Verifica que el dispositivo esté en la misma red

### Error de Supabase

1. Confirma las credenciales en `.env`
2. Verifica que las tablas estén creadas
3. Revisa los logs del servidor

### Flutter pub get falla

```bash
flutter clean
flutter pub get
```

## 📈 Roadmap

- [x] Implementar módulo de Citas completo
- [x] Generación completa de PDF con reportes detallados
- [ ] Sistema de notificaciones push
- [ ] Backup automático de datos
- [ ] Dashboard con gráficos
- [ ] Modo offline con sincronización
- [ ] Sistema de usuarios y roles
- [ ] Integración con pagos digitales

## 👥 Contribución

Para contribuir al proyecto:
1. Crea un fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/NuevaFuncionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/NuevaFuncionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es privado y de uso interno para Penguin Ternos.

## 📞 Contacto

Para soporte técnico o consultas, contacta al equipo de desarrollo.

---

**Penguin Ternos** - Sistema de Gestión v1.0.0
