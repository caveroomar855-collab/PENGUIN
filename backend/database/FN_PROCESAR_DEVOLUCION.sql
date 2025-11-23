-- SQL: Función atómica para procesar devoluciones de un alquiler
-- Ejecutar en Supabase SQL editor (o psql conectado a la BD de Supabase)
-- Uso:
-- SELECT fn_procesar_devolucion(
--   'alquiler-uuid',
--   '[{"articulo_id":"uuid1","estado_devolucion":"completo"},{"articulo_id":"uuid2","estado_devolucion":"perdido"}]'::jsonb,
--   0, -- mora_cobrada (opcional)
--   0, -- garantia_retenida (opcional)
--   'Motivo retención' -- descripcion_retencion (opcional)
-- );

CREATE OR REPLACE FUNCTION public.fn_procesar_devolucion(
  p_alquiler uuid,
  p_articulos jsonb,
  p_mora numeric DEFAULT 0,
  p_garantia_retenida numeric DEFAULT 0,
  p_descripcion text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  elem jsonb;
  v_articulo_id uuid;
  v_estado text;
  v_new_cantidad integer;
  v_rec record;
BEGIN
  -- Validar existencia del alquiler
  PERFORM 1 FROM alquileres WHERE id = p_alquiler;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Alquiler no encontrado: %', p_alquiler;
  END IF;

  -- Procesar cada artículo descrito en el JSON
  FOR elem IN SELECT * FROM jsonb_array_elements(p_articulos)
  LOOP
    v_articulo_id := (elem->> 'articulo_id')::uuid;
    v_estado := lower(coalesce(elem->> 'estado_devolucion', ''));

    -- Actualizar registro en alquiler_articulos (estado del ítem dentro del alquiler)
    UPDATE alquiler_articulos
    SET estado = v_estado
    WHERE alquiler_id = p_alquiler
      AND articulo_id = v_articulo_id;

    IF v_estado = 'completo' THEN
      -- mantenimiento 24h
      UPDATE articulos
      SET cantidad_mantenimiento = cantidad_mantenimiento + 1,
          estado = 'mantenimiento',
          fecha_disponible = now() + interval '24 hours'
      WHERE id = v_articulo_id;

    ELSIF v_estado = 'dañado' OR v_estado = 'danado' OR v_estado = 'daniado' THEN
      -- mantenimiento 72h (acepta varias variantes sin tilde)
      UPDATE articulos
      SET cantidad_mantenimiento = cantidad_mantenimiento + 1,
          estado = 'mantenimiento',
          fecha_disponible = now() + interval '72 hours'
      WHERE id = v_articulo_id;

    ELSIF v_estado = 'perdido' THEN
      -- marcar como perdido: incrementar perdidos y decrementar cantidad
      UPDATE articulos
      SET cantidad_perdida = cantidad_perdida + 1,
          cantidad = GREATEST(cantidad - 1, 0)
      WHERE id = v_articulo_id
      RETURNING cantidad INTO v_new_cantidad;

      IF FOUND THEN
        IF v_new_cantidad = 0 THEN
          -- Intentar eliminar la fila si no hay referencias (p. ej. FK RESTRICT)
          BEGIN
            DELETE FROM articulos WHERE id = v_articulo_id;
          EXCEPTION WHEN foreign_key_violation THEN
            -- No se puede borrar por restricciones; dejarla con estado 'perdido'
            UPDATE articulos SET estado = 'perdido' WHERE id = v_articulo_id;
          END;
        END IF;
      END IF;
    ELSE
      -- Si el estado no coincide con los esperados, no hacemos más (podrías extender)
      RAISE NOTICE 'Estado de devolución desconocido para articulo %: %', v_articulo_id, v_estado;
    END IF;
  END LOOP;

  -- Actualizar el alquiler como devuelto y registrar retenciones/mora si se proporcionaron
  UPDATE alquileres
  SET estado = 'devuelto',
      fecha_devolucion = now(),
      mora_cobrada = p_mora,
      garantia_retenida = p_garantia_retenida,
      descripcion_retencion = p_descripcion
  WHERE id = p_alquiler;

  -- Nota: existen triggers que recalculan cantidades (cantidad_disponible, cantidad_alquilada)
  -- al actualizar el estado del alquiler a 'devuelto', por lo que no recalculamos manualmente aquí.

  RETURN;
END;
$$;

-- Fin de archivo
