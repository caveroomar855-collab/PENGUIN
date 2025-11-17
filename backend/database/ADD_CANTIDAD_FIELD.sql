-- ============================================================================
-- AGREGAR CAMPO CANTIDAD A ARTÍCULOS
-- ============================================================================
-- Ejecuta este script en Supabase SQL Editor
-- ============================================================================

-- 1. Agregar campo cantidad a la tabla articulos
ALTER TABLE articulos 
ADD COLUMN IF NOT EXISTS cantidad INTEGER DEFAULT 1 NOT NULL;

-- 2. Agregar campos para tracking de cantidades por estado
ALTER TABLE articulos 
ADD COLUMN IF NOT EXISTS cantidad_disponible INTEGER DEFAULT 1 NOT NULL,
ADD COLUMN IF NOT EXISTS cantidad_alquilada INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN IF NOT EXISTS cantidad_mantenimiento INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN IF NOT EXISTS cantidad_vendida INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN IF NOT EXISTS cantidad_perdida INTEGER DEFAULT 0 NOT NULL;

-- 3. Actualizar artículos existentes para tener cantidad = 1
UPDATE articulos 
SET cantidad = 1,
    cantidad_disponible = CASE WHEN estado = 'disponible' THEN 1 ELSE 0 END,
    cantidad_alquilada = CASE WHEN estado = 'alquilado' THEN 1 ELSE 0 END,
    cantidad_mantenimiento = CASE WHEN estado = 'mantenimiento' THEN 1 ELSE 0 END,
    cantidad_vendida = CASE WHEN estado = 'vendido' THEN 1 ELSE 0 END,
    cantidad_perdida = CASE WHEN estado = 'perdido' THEN 1 ELSE 0 END
WHERE cantidad IS NULL;

-- 4. Crear función para actualizar cantidades automáticamente
CREATE OR REPLACE FUNCTION actualizar_cantidades_articulo()
RETURNS TRIGGER AS $$
BEGIN
  -- Recalcular todas las cantidades basadas en alquiler_articulos y venta_articulos
  UPDATE articulos a
  SET 
    cantidad_alquilada = COALESCE((
      SELECT COUNT(*) 
      FROM alquiler_articulos aa
      JOIN alquileres al ON aa.alquiler_id = al.id
      WHERE aa.articulo_id = a.id 
        AND al.estado = 'activo'
    ), 0),
    cantidad_disponible = a.cantidad - COALESCE((
      SELECT COUNT(*) 
      FROM alquiler_articulos aa
      JOIN alquileres al ON aa.alquiler_id = al.id
      WHERE aa.articulo_id = a.id 
        AND al.estado = 'activo'
    ), 0) - a.cantidad_mantenimiento - a.cantidad_vendida - a.cantidad_perdida
  WHERE a.id = COALESCE(NEW.articulo_id, OLD.articulo_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Crear triggers para mantener cantidades actualizadas
DROP TRIGGER IF EXISTS trigger_actualizar_cantidades_alquiler ON alquiler_articulos;
CREATE TRIGGER trigger_actualizar_cantidades_alquiler
AFTER INSERT OR UPDATE OR DELETE ON alquiler_articulos
FOR EACH ROW
EXECUTE FUNCTION actualizar_cantidades_articulo();

DROP TRIGGER IF EXISTS trigger_actualizar_cantidades_venta ON venta_articulos;
CREATE TRIGGER trigger_actualizar_cantidades_venta
AFTER INSERT OR UPDATE OR DELETE ON venta_articulos
FOR EACH ROW
EXECUTE FUNCTION actualizar_cantidades_articulo();

-- 6. Eliminar el campo 'estado' individual (ya no se usa, usamos las cantidades)
-- NO ejecutar esta línea aún, primero vamos a migrar toda la lógica
-- ALTER TABLE articulos DROP COLUMN IF EXISTS estado;

-- 7. Comentarios para el equipo
COMMENT ON COLUMN articulos.cantidad IS 'Cantidad total de este tipo de artículo en inventario';
COMMENT ON COLUMN articulos.cantidad_disponible IS 'Cantidad disponible para alquilar/vender';
COMMENT ON COLUMN articulos.cantidad_alquilada IS 'Cantidad actualmente alquilada';
COMMENT ON COLUMN articulos.cantidad_mantenimiento IS 'Cantidad en mantenimiento';
COMMENT ON COLUMN articulos.cantidad_vendida IS 'Cantidad vendida (disminuye inventario)';
COMMENT ON COLUMN articulos.cantidad_perdida IS 'Cantidad perdida (disminuye inventario)';
