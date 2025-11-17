# Esquema de Base de Datos - Penguin Ternos

## Instrucciones para crear las tablas en Supabase

Ejecuta estos comandos SQL en el editor SQL de Supabase:

```sql
-- Tabla de Clientes
CREATE TABLE clientes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  dni VARCHAR(20) UNIQUE NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  email VARCHAR(255),
  descripcion TEXT,
  en_papelera BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Artículos
CREATE TABLE articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  tipo VARCHAR(50) NOT NULL, -- 'saco', 'chaleco', 'pantalon', 'camisa', 'zapato', 'extra'
  talla VARCHAR(20),
  color VARCHAR(50),
  precio_alquiler DECIMAL(10, 2) NOT NULL,
  precio_venta DECIMAL(10, 2) NOT NULL,
  estado VARCHAR(50) DEFAULT 'disponible', -- 'disponible', 'alquilado', 'mantenimiento', 'vendido', 'perdido'
  fecha_disponible TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Trajes (agrupaciones de artículos)
CREATE TABLE trajes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de relación entre Trajes y Artículos
CREATE TABLE traje_articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  traje_id UUID REFERENCES trajes(id) ON DELETE CASCADE,
  articulo_id UUID REFERENCES articulos(id) ON DELETE CASCADE,
  UNIQUE(traje_id, articulo_id)
);

-- Tabla de Alquileres
CREATE TABLE alquileres (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id UUID REFERENCES clientes(id) ON DELETE RESTRICT,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  fecha_devolucion TIMESTAMP WITH TIME ZONE,
  monto_alquiler DECIMAL(10, 2) NOT NULL,
  garantia DECIMAL(10, 2) NOT NULL,
  garantia_retenida DECIMAL(10, 2) DEFAULT 0,
  mora_cobrada DECIMAL(10, 2) DEFAULT 0,
  metodo_pago VARCHAR(50) NOT NULL,
  observaciones TEXT,
  descripcion_retencion TEXT,
  estado VARCHAR(50) DEFAULT 'activo', -- 'activo', 'devuelto', 'perdido'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Artículos en Alquileres
CREATE TABLE alquiler_articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  alquiler_id UUID REFERENCES alquileres(id) ON DELETE CASCADE,
  articulo_id UUID REFERENCES articulos(id) ON DELETE RESTRICT,
  estado VARCHAR(50) DEFAULT 'alquilado', -- 'alquilado', 'completo', 'dañado', 'perdido'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Ventas
CREATE TABLE ventas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id UUID REFERENCES clientes(id) ON DELETE RESTRICT,
  total DECIMAL(10, 2) NOT NULL,
  metodo_pago VARCHAR(50) NOT NULL,
  estado VARCHAR(50) DEFAULT 'completada', -- 'completada', 'devuelta'
  fecha_devolucion TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Artículos en Ventas
CREATE TABLE venta_articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  venta_id UUID REFERENCES ventas(id) ON DELETE CASCADE,
  articulo_id UUID REFERENCES articulos(id) ON DELETE RESTRICT,
  precio DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Citas
CREATE TABLE citas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
  fecha TIMESTAMP WITH TIME ZONE NOT NULL,
  descripcion TEXT,
  estado VARCHAR(50) DEFAULT 'pendiente', -- 'pendiente', 'completada', 'cancelada'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de Configuración (solo una fila)
CREATE TABLE configuracion (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre_empleado VARCHAR(255) DEFAULT 'Empleado',
  tema_oscuro BOOLEAN DEFAULT FALSE,
  garantia_default DECIMAL(10, 2) DEFAULT 50.0,
  mora_diaria DECIMAL(10, 2) DEFAULT 10.0,
  dias_maximos_mora INTEGER DEFAULT 7,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_clientes_dni ON clientes(dni);
CREATE INDEX idx_clientes_papelera ON clientes(en_papelera);
CREATE INDEX idx_articulos_estado ON articulos(estado);
CREATE INDEX idx_articulos_tipo ON articulos(tipo);
CREATE INDEX idx_alquileres_estado ON alquileres(estado);
CREATE INDEX idx_alquileres_cliente ON alquileres(cliente_id);
CREATE INDEX idx_ventas_cliente ON ventas(cliente_id);
CREATE INDEX idx_ventas_estado ON ventas(estado);

-- Triggers para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_clientes_updated_at BEFORE UPDATE ON clientes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_articulos_updated_at BEFORE UPDATE ON articulos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alquileres_updated_at BEFORE UPDATE ON alquileres
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ventas_updated_at BEFORE UPDATE ON ventas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_citas_updated_at BEFORE UPDATE ON citas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_configuracion_updated_at BEFORE UPDATE ON configuracion
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Datos de ejemplo (opcional)

```sql
-- Insertar configuración inicial
INSERT INTO configuracion (nombre_empleado, tema_oscuro, garantia_default, mora_diaria, dias_maximos_mora)
VALUES ('Empleado', FALSE, 50.0, 10.0, 7);

-- Insertar artículos de ejemplo
INSERT INTO articulos (codigo, nombre, tipo, talla, color, precio_alquiler, precio_venta, estado)
VALUES 
  ('SAC001', 'Saco Negro Clásico', 'saco', 'M', 'Negro', 30.0, 200.0, 'disponible'),
  ('PAN001', 'Pantalón Negro Formal', 'pantalon', 'M', 'Negro', 20.0, 120.0, 'disponible'),
  ('CAM001', 'Camisa Blanca Premium', 'camisa', 'M', 'Blanco', 15.0, 80.0, 'disponible'),
  ('ZAP001', 'Zapatos Negros Elegantes', 'zapato', '42', 'Negro', 25.0, 150.0, 'disponible'),
  ('CHAL001', 'Chaleco Gris Perla', 'chaleco', 'M', 'Gris', 20.0, 100.0, 'disponible');
```
