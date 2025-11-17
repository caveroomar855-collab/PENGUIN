# Backend - Penguin Ternos

API RESTful para el sistema de gestión de alquiler y venta de ternos.

## Instalación

1. Instalar dependencias:
```bash
npm install
```

2. Configurar variables de entorno:
   - Copia `.env.example` a `.env`
   - Agrega tus credenciales de Supabase

3. Crear las tablas en Supabase:
   - Ve a `database/schema.md` y ejecuta el SQL en tu proyecto de Supabase

## Iniciar el servidor

### Modo desarrollo (con reinicio automático):
```bash
npm run dev
```

### Modo producción:
```bash
npm start
```

El servidor se iniciará en `http://localhost:3000`

## Endpoints

### Clientes
- `GET /api/clientes` - Obtener todos los clientes
- `GET /api/clientes/papelera` - Obtener clientes en papelera
- `GET /api/clientes/dni/:dni` - Buscar cliente por DNI
- `POST /api/clientes` - Crear cliente
- `PUT /api/clientes/:id` - Actualizar cliente
- `PATCH /api/clientes/:id/papelera` - Enviar a papelera
- `PATCH /api/clientes/:id/restaurar` - Restaurar de papelera
- `DELETE /api/clientes/:id` - Eliminar permanentemente

### Alquileres
- `GET /api/alquileres/activos` - Obtener alquileres activos
- `GET /api/alquileres/historial` - Obtener historial
- `GET /api/alquileres/:id` - Obtener alquiler por ID
- `POST /api/alquileres` - Crear alquiler
- `POST /api/alquileres/:id/devolucion` - Marcar devolución

### Ventas
- `GET /api/ventas` - Obtener todas las ventas
- `GET /api/ventas/:id` - Obtener venta por ID
- `POST /api/ventas` - Crear venta
- `POST /api/ventas/:id/devolucion` - Procesar devolución

### Inventario
- `GET /api/inventario/articulos` - Obtener todos los artículos
- `GET /api/inventario/articulos/estado/:estado` - Filtrar por estado
- `GET /api/inventario/trajes` - Obtener todos los trajes
- `GET /api/inventario/trajes/:id` - Obtener traje por ID
- `POST /api/inventario/articulos` - Crear artículo
- `PUT /api/inventario/articulos/:id` - Actualizar artículo
- `PATCH /api/inventario/articulos/:id/mantenimiento` - Cambiar estado de mantenimiento
- `POST /api/inventario/trajes` - Crear traje

### Reportes
- `GET /api/reportes/resumen-dia` - Obtener resumen del día
- `POST /api/reportes/alquileres` - Generar reporte de alquileres
- `POST /api/reportes/ventas` - Generar reporte de ventas

### Configuración
- `GET /api/configuracion` - Obtener configuración
- `PUT /api/configuracion` - Actualizar configuración

## Estructura del proyecto

```
backend/
├── config/
│   └── database.js      # Configuración de Supabase
├── routes/
│   ├── clientes.js      # Rutas de clientes
│   ├── alquileres.js    # Rutas de alquileres
│   ├── ventas.js        # Rutas de ventas
│   ├── inventario.js    # Rutas de inventario
│   ├── reportes.js      # Rutas de reportes
│   └── configuracion.js # Rutas de configuración
├── database/
│   └── schema.md        # Esquema de base de datos
├── .env.example         # Ejemplo de variables de entorno
├── .gitignore
├── package.json
└── server.js            # Punto de entrada
```
