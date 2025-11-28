-- Test script for fn_procesar_devolucion_safe: partial then final return
-- WARNING: This script inserts test rows into the database. Run in a test/schema you can wipe.

BEGIN;

-- Create a sample articulo
INSERT INTO articulos (id, nombre, tipo, cantidad, cantidad_disponible, precio_alquiler, precio_venta, estado)
VALUES (
  gen_random_uuid(), 'TEST_ART', 'saco', 2, 2, 10.0, 50.0, 'disponible'
) RETURNING id INTO TEMPORARY TABLE tmp_art (id uuid);

-- Create a sample cliente
INSERT INTO clientes (id, nombre, dni, telefono)
VALUES (gen_random_uuid(), 'Cliente Test', '12345678', '999999999') RETURNING id INTO TEMPORARY TABLE tmp_cliente (id uuid);

-- Create a sample alquiler
INSERT INTO alquileres (id, cliente_id, fecha_inicio, fecha_fin, monto_alquiler, garantia, estado)
VALUES (gen_random_uuid(), (SELECT id FROM tmp_cliente LIMIT 1), now() - interval '5 days', now() + interval '2 days', 20.0, 50.0, 'activo') RETURNING id INTO TEMPORARY TABLE tmp_alq (id uuid);

-- Expand into two alquiler_articulos (2 units)
INSERT INTO alquiler_articulos (alquiler_id, articulo_id, estado)
SELECT (SELECT id FROM tmp_alq LIMIT 1), (SELECT id FROM tmp_art LIMIT 1), 'alquilado'
UNION ALL
SELECT (SELECT id FROM tmp_alq LIMIT 1), (SELECT id FROM tmp_art LIMIT 1), 'alquilado';

-- Show initial state
SELECT 'INITIAL alquileres' as phase, a.* FROM alquileres a WHERE id = (SELECT id FROM tmp_alq LIMIT 1);
SELECT 'INITIAL alquiler_articulos' as phase, aa.* FROM alquiler_articulos aa WHERE alquiler_id = (SELECT id FROM tmp_alq LIMIT 1);

-- Simulate partial return: return 1 unit as 'completo'
SELECT public.fn_procesar_devolucion_safe(
  (SELECT id FROM tmp_alq LIMIT 1),
  jsonb_build_array(jsonb_build_object('articulo_id', (SELECT id FROM tmp_art LIMIT 1), 'estado_devolucion', 'completo', 'cantidad', 1)),
  0, 0, null
);

-- State after partial return
SELECT 'AFTER PARTIAL alquileres' as phase, a.* FROM alquileres a WHERE id = (SELECT id FROM tmp_alq LIMIT 1);
SELECT 'AFTER PARTIAL alquiler_articulos' as phase, aa.* FROM alquiler_articulos aa WHERE alquiler_id = (SELECT id FROM tmp_alq LIMIT 1);

-- Simulate final return: return remaining 1 unit as 'completo'
SELECT public.fn_procesar_devolucion_safe(
  (SELECT id FROM tmp_alq LIMIT 1),
  jsonb_build_array(jsonb_build_object('articulo_id', (SELECT id FROM tmp_art LIMIT 1), 'estado_devolucion', 'completo', 'cantidad', 1)),
  0, 0, null
);

-- Final state
SELECT 'AFTER FINAL alquileres' as phase, a.* FROM alquileres a WHERE id = (SELECT id FROM tmp_alq LIMIT 1);
SELECT 'AFTER FINAL alquiler_articulos' as phase, aa.* FROM alquiler_articulos aa WHERE alquiler_id = (SELECT id FROM tmp_alq LIMIT 1);

ROLLBACK; -- rollback test data so DB remains unchanged

-- End of test script
