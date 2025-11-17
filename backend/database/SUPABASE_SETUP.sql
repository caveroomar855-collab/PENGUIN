-- ============================================================================
-- PENGUIN TERNOS - SCHEMA COMPLETO PARA SUPABASE
-- ============================================================================
-- Ejecuta este script completo en el SQL Editor de Supabase
-- Ve a: SQL Editor > New Query > Pega este código > Run
-- ============================================================================

-- TABLA: Clientes
-- Almacena información de los clientes de la tienda
CREATE TABLE IF NOT EXISTS clientes (
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

-- TABLA: Artículos
-- Almacena los artículos individuales disponibles para alquiler/venta
CREATE TABLE IF NOT EXISTS articulos (
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

-- TABLA: Trajes
-- Agrupaciones de artículos para facilitar la selección
CREATE TABLE IF NOT EXISTS trajes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA: Relación Traje-Artículos
-- Relaciona trajes con sus artículos componentes
CREATE TABLE IF NOT EXISTS traje_articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  traje_id UUID REFERENCES trajes(id) ON DELETE CASCADE,
  articulo_id UUID REFERENCES articulos(id) ON DELETE CASCADE,
  UNIQUE(traje_id, articulo_id)
);

-- TABLA: Alquileres
-- Registra los alquileres de artículos
CREATE TABLE IF NOT EXISTS alquileres (
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

-- TABLA: Artículos en Alquileres
-- Relaciona alquileres con artículos específicos y su estado
CREATE TABLE IF NOT EXISTS alquiler_articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  alquiler_id UUID REFERENCES alquileres(id) ON DELETE CASCADE,
  articulo_id UUID REFERENCES articulos(id) ON DELETE RESTRICT,
  estado VARCHAR(50) DEFAULT 'alquilado', -- 'alquilado', 'completo', 'dañado', 'perdido'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA: Ventas
-- Registra las ventas de artículos
CREATE TABLE IF NOT EXISTS ventas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id UUID REFERENCES clientes(id) ON DELETE RESTRICT,
  total DECIMAL(10, 2) NOT NULL,
  metodo_pago VARCHAR(50) NOT NULL,
  estado VARCHAR(50) DEFAULT 'completada', -- 'completada', 'devuelta'
  fecha_devolucion TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA: Artículos en Ventas
-- Relaciona ventas con artículos específicos
CREATE TABLE IF NOT EXISTS venta_articulos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  venta_id UUID REFERENCES ventas(id) ON DELETE CASCADE,
  articulo_id UUID REFERENCES articulos(id) ON DELETE RESTRICT,
  precio DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA: Citas
-- Almacena citas programadas con clientes
CREATE TABLE IF NOT EXISTS citas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
  fecha TIMESTAMP WITH TIME ZONE NOT NULL,
  descripcion TEXT,
  estado VARCHAR(50) DEFAULT 'pendiente', -- 'pendiente', 'completada', 'cancelada'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA: Configuración
-- Almacena configuración global del sistema (solo una fila)
CREATE TABLE IF NOT EXISTS configuracion (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre_empleado VARCHAR(255) DEFAULT 'Empleado',
  tema_oscuro BOOLEAN DEFAULT FALSE,
  garantia_default DECIMAL(10, 2) DEFAULT 50.0,
  mora_diaria DECIMAL(10, 2) DEFAULT 10.0,
  dias_maximos_mora INTEGER DEFAULT 7,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- ÍNDICES para mejorar el rendimiento de las consultas
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_clientes_dni ON clientes(dni);
CREATE INDEX IF NOT EXISTS idx_clientes_papelera ON clientes(en_papelera);
CREATE INDEX IF NOT EXISTS idx_clientes_nombre ON clientes(nombre);

CREATE INDEX IF NOT EXISTS idx_articulos_estado ON articulos(estado);
CREATE INDEX IF NOT EXISTS idx_articulos_tipo ON articulos(tipo);
CREATE INDEX IF NOT EXISTS idx_articulos_codigo ON articulos(codigo);

CREATE INDEX IF NOT EXISTS idx_alquileres_estado ON alquileres(estado);
CREATE INDEX IF NOT EXISTS idx_alquileres_cliente ON alquileres(cliente_id);
CREATE INDEX IF NOT EXISTS idx_alquileres_fecha_inicio ON alquileres(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_alquileres_fecha_fin ON alquileres(fecha_fin);

CREATE INDEX IF NOT EXISTS idx_ventas_cliente ON ventas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_ventas_estado ON ventas(estado);
CREATE INDEX IF NOT EXISTS idx_ventas_created ON ventas(created_at);

CREATE INDEX IF NOT EXISTS idx_citas_fecha ON citas(fecha);
CREATE INDEX IF NOT EXISTS idx_citas_estado ON citas(estado);

-- ============================================================================
-- FUNCIÓN: Actualizar timestamp automáticamente
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS: Actualizar updated_at en cada UPDATE
-- ============================================================================

DROP TRIGGER IF EXISTS update_clientes_updated_at ON clientes;
CREATE TRIGGER update_clientes_updated_at 
  BEFORE UPDATE ON clientes
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_articulos_updated_at ON articulos;
CREATE TRIGGER update_articulos_updated_at 
  BEFORE UPDATE ON articulos
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_alquileres_updated_at ON alquileres;
CREATE TRIGGER update_alquileres_updated_at 
  BEFORE UPDATE ON alquileres
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ventas_updated_at ON ventas;
CREATE TRIGGER update_ventas_updated_at 
  BEFORE UPDATE ON ventas
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_citas_updated_at ON citas;
CREATE TRIGGER update_citas_updated_at 
  BEFORE UPDATE ON citas
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_configuracion_updated_at ON configuracion;
CREATE TRIGGER update_configuracion_updated_at 
  BEFORE UPDATE ON configuracion
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCIÓN: Actualizar estado de artículos en mantenimiento
-- Esta función puede ejecutarse periódicamente para liberar artículos
-- ============================================================================

CREATE OR REPLACE FUNCTION liberar_articulos_mantenimiento()
RETURNS void AS $$
BEGIN
  UPDATE articulos
  SET estado = 'disponible', fecha_disponible = NULL
  WHERE estado = 'mantenimiento'
    AND fecha_disponible IS NOT NULL
    AND fecha_disponible <= NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- POLÍTICAS DE SEGURIDAD (RLS)
-- Por ahora deshabilitadas para facilitar el desarrollo
-- Puedes habilitarlas más adelante para mayor seguridad
-- ============================================================================

-- Deshabilitar RLS en todas las tablas (para desarrollo)
ALTER TABLE clientes DISABLE ROW LEVEL SECURITY;
ALTER TABLE articulos DISABLE ROW LEVEL SECURITY;
ALTER TABLE trajes DISABLE ROW LEVEL SECURITY;
ALTER TABLE traje_articulos DISABLE ROW LEVEL SECURITY;
ALTER TABLE alquileres DISABLE ROW LEVEL SECURITY;
ALTER TABLE alquiler_articulos DISABLE ROW LEVEL SECURITY;
ALTER TABLE ventas DISABLE ROW LEVEL SECURITY;
ALTER TABLE venta_articulos DISABLE ROW LEVEL SECURITY;
ALTER TABLE citas DISABLE ROW LEVEL SECURITY;
ALTER TABLE configuracion DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DATOS INICIALES: Configuración por defecto
-- ============================================================================

INSERT INTO configuracion (nombre_empleado, tema_oscuro, garantia_default, mora_diaria, dias_maximos_mora)
VALUES ('Empleado', FALSE, 50.0, 10.0, 7)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- DATOS DE EJEMPLO (OPCIONAL - Descomenta si quieres datos de prueba)
-- ============================================================================

-- Artículos de ejemplo
/*
INSERT INTO articulos (codigo, nombre, tipo, talla, color, precio_alquiler, precio_venta, estado)
VALUES 
  ('SAC001', 'Saco Negro Clásico', 'saco', 'M', 'Negro', 30.0, 200.0, 'disponible'),
  ('SAC002', 'Saco Gris Oxford', 'saco', 'L', 'Gris', 35.0, 220.0, 'disponible'),
  ('SAC003', 'Saco Azul Marino', 'saco', 'M', 'Azul', 32.0, 210.0, 'disponible'),
  
  ('PAN001', 'Pantalón Negro Formal', 'pantalon', '32', 'Negro', 20.0, 120.0, 'disponible'),
  ('PAN002', 'Pantalón Gris Vestir', 'pantalon', '34', 'Gris', 22.0, 130.0, 'disponible'),
  ('PAN003', 'Pantalón Azul Marino', 'pantalon', '32', 'Azul', 20.0, 125.0, 'disponible'),
  
  ('CAM001', 'Camisa Blanca Premium', 'camisa', 'M', 'Blanco', 15.0, 80.0, 'disponible'),
  ('CAM002', 'Camisa Blanca Slim Fit', 'camisa', 'L', 'Blanco', 15.0, 85.0, 'disponible'),
  ('CAM003', 'Camisa Celeste', 'camisa', 'M', 'Celeste', 15.0, 80.0, 'disponible'),
  
  ('ZAP001', 'Zapatos Negros Elegantes', 'zapato', '42', 'Negro', 25.0, 150.0, 'disponible'),
  ('ZAP002', 'Zapatos Marrones Oxford', 'zapato', '43', 'Marrón', 25.0, 160.0, 'disponible'),
  ('ZAP003', 'Zapatos Negros Derby', 'zapato', '41', 'Negro', 25.0, 155.0, 'disponible'),
  
  ('CHAL001', 'Chaleco Gris Perla', 'chaleco', 'M', 'Gris', 20.0, 100.0, 'disponible'),
  ('CHAL002', 'Chaleco Negro Formal', 'chaleco', 'L', 'Negro', 20.0, 105.0, 'disponible'),
  ('CHAL003', 'Chaleco Azul Marino', 'chaleco', 'M', 'Azul', 20.0, 100.0, 'disponible'),
  
  ('CORB001', 'Corbata Negra Lisa', 'extra', NULL, 'Negro', 5.0, 30.0, 'disponible'),
  ('CORB002', 'Corbata Azul Rayas', 'extra', NULL, 'Azul', 5.0, 35.0, 'disponible'),
  ('CORB003', 'Corbata Roja Elegante', 'extra', NULL, 'Rojo', 5.0, 35.0, 'disponible');

-- Trajes de ejemplo
INSERT INTO trajes (nombre, descripcion)
VALUES 
  ('Traje Clásico Negro M', 'Traje completo negro talla M para eventos formales'),
  ('Traje Ejecutivo Gris L', 'Traje gris talla L ideal para negocios'),
  ('Traje Moderno Azul M', 'Traje azul marino talla M estilo contemporáneo');

-- Asociar artículos a trajes (ejemplo con el primer traje)
INSERT INTO traje_articulos (traje_id, articulo_id)
SELECT 
  (SELECT id FROM trajes WHERE nombre = 'Traje Clásico Negro M'),
  id
FROM articulos
WHERE codigo IN ('SAC001', 'PAN001', 'CAM001', 'ZAP001', 'CHAL001');

-- Cliente de ejemplo
INSERT INTO clientes (dni, nombre, telefono, email, descripcion)
VALUES 
  ('12345678', 'Juan Pérez García', '987654321', 'juan.perez@email.com', 'Cliente frecuente'),
  ('87654321', 'María López Rojas', '912345678', 'maria.lopez@email.com', 'Cliente VIP');
*/

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================

-- VERIFICACIÓN: Ejecuta estas consultas para verificar que todo se creó correctamente
/*
SELECT 'Tablas creadas:' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

SELECT 'Total de artículos:' as info, COUNT(*) as total FROM articulos;
SELECT 'Total de clientes:' as info, COUNT(*) as total FROM clientes;
SELECT 'Configuración:' as info, * FROM configuracion;
*/
