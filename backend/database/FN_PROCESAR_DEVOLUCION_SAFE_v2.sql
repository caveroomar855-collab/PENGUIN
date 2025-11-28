-- Versión final (v2) segura de la función de procesamiento de devoluciones
-- Selecciona hasta N filas unitarias en alquiler_articulos y usa
-- la cantidad realmente afectada para actualizar articulos.

CREATE OR REPLACE FUNCTION public.fn_procesar_devolucion_safe(
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
  v_old_cantidad integer;
  v_cantidad integer;
  v_ids uuid[];
  v_rec RECORD;
  v_affected integer;
  v_remaining integer;
BEGIN
  -- Validar existencia del alquiler
  PERFORM 1 FROM alquileres WHERE id = p_alquiler;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Alquiler no encontrado: %', p_alquiler;
  END IF;

  FOR elem IN SELECT * FROM jsonb_array_elements(p_articulos)
  LOOP
    v_articulo_id := (elem->> 'articulo_id')::uuid;
    v_estado := lower(coalesce(elem->> 'estado_devolucion', ''));
    v_cantidad := coalesce((elem->> 'cantidad')::int, 1);

    -- Actualizar estado en alquiler_articulos
    -- Seleccionar hasta v_cantidad filas de alquiler_articulos correspondientes (por unidad)
    -- y marcarlas con FOR UPDATE para evitar race conditions.
    v_ids := ARRAY[]::uuid[];
    v_affected := 0;
    FOR v_rec IN
      SELECT id FROM alquiler_articulos
      WHERE alquiler_id = p_alquiler
        AND articulo_id = v_articulo_id
        AND estado = 'alquilado'
      ORDER BY id
      LIMIT v_cantidad
      FOR UPDATE
    LOOP
      v_ids := array_append(v_ids, v_rec.id::uuid);
    END LOOP;

    IF array_length(v_ids, 1) IS NOT NULL THEN
      UPDATE alquiler_articulos
      SET estado = v_estado
      WHERE id = ANY(v_ids);
      v_affected := array_length(v_ids, 1);
    ELSE
      v_affected := 0;
    END IF;

    -- NOTE: Do NOT automatically move returned items into maintenance.
    -- The client will explicitly put items into maintenance via inventory UI.
    IF v_estado = 'completo' THEN
      -- No automatic maintenance update for 'completo'.
      NULL; -- intentional no-op

    ELSIF v_estado = 'dañado' OR v_estado = 'danado' OR v_estado = 'daniado' THEN
      -- No automatic maintenance update for damaged returns.
      NULL; -- intentional no-op

    ELSIF v_estado = 'perdido' THEN
      -- Lock the row and read previous cantidad
      SELECT cantidad INTO v_old_cantidad FROM articulos WHERE id = v_articulo_id FOR UPDATE;

      IF NOT FOUND THEN
        RAISE NOTICE 'Artículo no encontrado al procesar perdido: %', v_articulo_id;
        CONTINUE;
      END IF;

      IF v_affected > 0 THEN
        -- Decrementar la cantidad realmente afectada, sin eliminar la fila.
        UPDATE articulos
        SET cantidad = GREATEST(cantidad - v_affected, 0),
            cantidad_perdida = cantidad_perdida + v_affected,
            estado = CASE WHEN (cantidad - v_affected) <= 0 THEN 'perdido' ELSE estado END
        WHERE id = v_articulo_id;
      END IF;

    ELSE
      RAISE NOTICE 'Estado de devolución desconocido para articulo %: %', v_articulo_id, v_estado;
    END IF;
  END LOOP;

  -- Si no quedan unidades en estado 'alquilado', marcar alquiler como devuelto
  SELECT COUNT(*) INTO v_remaining
  FROM alquiler_articulos
  WHERE alquiler_id = p_alquiler
    AND estado = 'alquilado';

  IF v_remaining = 0 THEN
    -- Marcar alquiler como devuelto y registrar datos (mora/garantía aplican al cierre)
    UPDATE alquileres
    SET estado = 'devuelto',
        fecha_devolucion = now(),
        mora_cobrada = p_mora,
        garantia_retenida = p_garantia_retenida,
        descripcion_retencion = p_descripcion
    WHERE id = p_alquiler;
  ELSE
    -- Parcial: dejar el alquiler abierto para que la mora siga corriendo.
    -- No actualizar mora_cobrada ni fecha_devolucion hasta el cierre.
    RAISE NOTICE 'Devolución parcial procesada para alquiler %; quedan % unidades alquiladas', p_alquiler, v_remaining;
  END IF;

  RETURN;
END;
$$;
