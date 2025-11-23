-- Migration: Recalculate `cantidad_*` for all articulos
-- Path: backend/database/RECALC_CANTIDADES.sql
-- Purpose: Provide a safe function to recalculate per-article inventory counters
-- Notes: This does not modify triggers; it recomputes values from related tables

-- Create helper function
CREATE OR REPLACE FUNCTION fn_recalcular_cantidades_articulo(p_articulo uuid)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_alquilada integer := 0;
  v_vendida integer := 0;
  v_perdida integer := 0;
  v_mantenimiento integer := 0;
  v_total integer := 0;
BEGIN
  -- Active rentals: count rental items linked to active rentals
  SELECT COUNT(*) INTO v_alquilada
  FROM alquiler_articulos aa
  JOIN alquileres al ON aa.alquiler_id = al.id
  WHERE aa.articulo_id = p_articulo
    AND al.estado = 'activo';

  -- Sold quantities: sum quantities from ventas that are not in a 'devuelta' state
  SELECT COALESCE(SUM(va.cantidad), 0) INTO v_vendida
  FROM venta_articulos va
  JOIN ventas v ON va.venta_id = v.id
  WHERE va.articulo_id = p_articulo
    AND (v.estado IS NULL OR v.estado != 'devuelta');

  -- Keep existing perdida and mantenimiento values when there is no external source
  SELECT COALESCE(cantidad_perdida, 0), COALESCE(cantidad_mantenimiento, 0), COALESCE(cantidad, 0)
  INTO v_perdida, v_mantenimiento, v_total
  FROM articulos
  WHERE id = p_articulo;

  -- Update articulos with recalculated values
  -- NOTA: `v_total` ya representa la cantidad física actual; `v_perdida` se mantiene para reportes
  UPDATE articulos
  SET
    cantidad_alquilada = v_alquilada,
    cantidad_vendida = v_vendida,
    cantidad_disponible = GREATEST(v_total - v_alquilada - v_mantenimiento - v_vendida, 0),
    updated_at = NOW()
  WHERE id = p_articulo;
END;
$$;

-- Execute recalculation for all articulos
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT id FROM articulos LOOP
    PERFORM fn_recalcular_cantidades_articulo(r.id);
  END LOOP;
END;
$$;

-- End of migration
