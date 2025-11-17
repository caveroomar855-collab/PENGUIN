# 🚀 CONFIGURACIÓN RÁPIDA - PENGUIN TERNOS

## ✅ PASO 1: Configurar Supabase (5 minutos)

### 1.1 Crear las tablas en Supabase

1. Ve a tu proyecto de Supabase: https://supabase.com/dashboard/project/hqqprbxhfljarfptzsdb

2. En el menú lateral, haz clic en **"SQL Editor"**

3. Haz clic en **"+ New Query"**

4. Abre el archivo: `c:\a\backend\database\SUPABASE_SETUP.sql`

5. **COPIA TODO EL CONTENIDO** del archivo

6. **PEGA** en el editor SQL de Supabase

7. Haz clic en **"RUN"** (o presiona Ctrl+Enter)

8. Espera unos segundos. Deberías ver el mensaje: **"Success. No rows returned"**

9. ✅ ¡Listo! Todas las tablas, índices y funciones están creadas

### 1.2 Verificar que se crearon las tablas

En el mismo SQL Editor, ejecuta esta consulta:

```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

Deberías ver estas tablas:
- alquiler_articulos
- alquileres
- articulos
- citas
- clientes
- configuracion
- traje_articulos
- trajes
- venta_articulos
- ventas

---

## ✅ PASO 2: Configurar el Backend (2 minutos)

### 2.1 Configurar las variables de entorno

1. Abre PowerShell y navega al backend:
   ```powershell
   cd c:\a\backend
   ```

2. Crea el archivo `.env` desde el ejemplo:
   ```powershell
   copy .env.example .env
   ```

3. ¡Ya está configurado! El archivo `.env.example` ya tiene tus credenciales:
   - ✅ URL: `https://hqqprbxhfljarfptzsdb.supabase.co`
   - ✅ KEY: Tu `anon public` key (la correcta)

### 2.2 Instalar dependencias

```powershell
npm install
```

Espera 2-3 minutos mientras se descargan las dependencias.

### 2.3 Iniciar el servidor

```powershell
npm start
```

Deberías ver:
```
Servidor corriendo en http://localhost:3000
```

✅ **¡El backend está listo!**

### 2.4 Probar que funciona

Abre un navegador y ve a: http://localhost:3000

Deberías ver:
```json
{"message":"API de Penguin Ternos funcionando correctamente"}
```

**IMPORTANTE:** Deja esta ventana de PowerShell abierta mientras uses la app.

---

## ✅ PASO 3: Configurar Flutter (3 minutos)

### 3.1 Obtener tu IP local (solo si usas dispositivo físico)

Si usarás un dispositivo Android físico (conectado por USB o WiFi):

```powershell
ipconfig
```

Busca tu IP en "Adaptador de LAN inalámbrica Wi-Fi" → "Dirección IPv4"
Ejemplo: `192.168.1.100`

### 3.2 Configurar la URL de la API

**Opción A: Si usas EMULADOR de Android**

El archivo ya está configurado correctamente con: `http://10.0.2.2:3000/api`

**Opción B: Si usas DISPOSITIVO FÍSICO**

1. Abre: `c:\a\flutter_app\lib\config\api_config.dart`

2. Cambia la línea 5:
   ```dart
   static const String baseUrl = 'http://TU_IP_AQUI:3000/api';
   ```
   
   Por ejemplo:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:3000/api';
   ```

3. Guarda el archivo

### 3.3 Instalar dependencias de Flutter

Abre OTRA ventana de PowerShell (deja la del backend abierta):

```powershell
cd c:\a\flutter_app
flutter pub get
```

### 3.4 Conectar dispositivo o emulador

Verifica que esté conectado:
```powershell
flutter devices
```

Deberías ver al menos un dispositivo.

### 3.5 Ejecutar la app

```powershell
flutter run
```

La primera vez tarda 3-5 minutos en compilar.

---

## ✅ PASO 4: Usar la App

1. La app mostrará el splash screen con el logo

2. Luego verás 4 pestañas: Inicio, Clientes, Reportes, Configuración

3. **Ve a "Configuración"** y configura:
   - Tu nombre
   - Garantía por defecto: `50`
   - Mora diaria: `10`
   - Días máximos de mora: `7`

4. Haz clic en **"Guardar Configuración"**

5. ✅ ¡Listo para usar!

---

## 🎯 RESUMEN DE CREDENCIALES

```
SUPABASE URL: https://hqqprbxhfljarfptzsdb.supabase.co

API KEY A USAR: anon public
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxcXByYnhoZmxqYXJmcHR6c2RiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyMzkzMzQsImV4cCI6MjA3ODgxNTMzNH0.oXkfhI1kMgradOiKOC0sbYLdEm2_sfkAOoYcgb4ugUY

NO USES: service_role (es solo para tareas administrativas)
```

---

## 📝 DATOS DE PRUEBA (OPCIONAL)

Si quieres agregar artículos de ejemplo para probar:

1. Ve a Supabase → SQL Editor

2. Ejecuta este código:

```sql
INSERT INTO articulos (codigo, nombre, tipo, talla, color, precio_alquiler, precio_venta, estado)
VALUES 
  ('SAC001', 'Saco Negro Clásico', 'saco', 'M', 'Negro', 30.0, 200.0, 'disponible'),
  ('PAN001', 'Pantalón Negro Formal', 'pantalon', '32', 'Negro', 20.0, 120.0, 'disponible'),
  ('CAM001', 'Camisa Blanca Premium', 'camisa', 'M', 'Blanco', 15.0, 80.0, 'disponible'),
  ('ZAP001', 'Zapatos Negros Elegantes', 'zapato', '42', 'Negro', 25.0, 150.0, 'disponible'),
  ('CHAL001', 'Chaleco Gris Perla', 'chaleco', 'M', 'Gris', 20.0, 100.0, 'disponible');

INSERT INTO clientes (dni, nombre, telefono, email)
VALUES 
  ('12345678', 'Juan Pérez García', '987654321', 'juan.perez@email.com'),
  ('87654321', 'María López Rojas', '912345678', 'maria.lopez@email.com');
```

---

## ❓ Solución de Problemas

### Error: "Cannot connect to Supabase"
- Verifica que ejecutaste el SQL en Supabase
- Verifica las credenciales en el archivo `.env`

### Error: "Connection refused" en la app
- Asegúrate de que el backend esté corriendo
- Verifica la URL en `api_config.dart`
- Si usas dispositivo físico, revisa la IP

### El backend no inicia
- Verifica que el puerto 3000 no esté en uso
- Reinstala las dependencias: `npm install`

---

## 🎉 ¡Listo!

Tu sistema está funcionando con:
- ✅ Base de datos en Supabase
- ✅ Backend en Node.js
- ✅ App en Flutter

Ahora puedes empezar a usar el sistema para gestionar alquileres y ventas.
