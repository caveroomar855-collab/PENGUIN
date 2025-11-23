create table public.alquiler_articulos (
  id uuid not null default gen_random_uuid (),
  alquiler_id uuid null,
  articulo_id uuid null,
  estado character varying(50) null default 'alquilado'::character varying,
  created_at timestamp with time zone null default now(),
  constraint alquiler_articulos_pkey primary key (id),
  constraint alquiler_articulos_alquiler_id_fkey foreign KEY (alquiler_id) references alquileres (id) on delete CASCADE,
  constraint alquiler_articulos_articulo_id_fkey foreign KEY (articulo_id) references articulos (id) on delete RESTRICT
) TABLESPACE pg_default;

create trigger trigger_actualizar_cantidades_alquiler
after INSERT
or DELETE
or
update on alquiler_articulos for EACH row
execute FUNCTION actualizar_cantidades_articulo ();

create table public.alquileres (
  id uuid not null default gen_random_uuid (),
  cliente_id uuid null,
  fecha_inicio date not null,
  fecha_fin date not null,
  fecha_devolucion timestamp with time zone null,
  monto_alquiler numeric(10, 2) not null,
  garantia numeric(10, 2) not null,
  garantia_retenida numeric(10, 2) null default 0,
  mora_cobrada numeric(10, 2) null default 0,
  metodo_pago character varying(50) not null,
  observaciones text null,
  descripcion_retencion text null,
  estado character varying(50) null default 'activo'::character varying,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint alquileres_pkey primary key (id),
  constraint alquileres_cliente_id_fkey foreign KEY (cliente_id) references clientes (id) on delete RESTRICT
) TABLESPACE pg_default;

create index IF not exists idx_alquileres_estado on public.alquileres using btree (estado) TABLESPACE pg_default;

create index IF not exists idx_alquileres_cliente on public.alquileres using btree (cliente_id) TABLESPACE pg_default;

create index IF not exists idx_alquileres_fecha_inicio on public.alquileres using btree (fecha_inicio) TABLESPACE pg_default;

create index IF not exists idx_alquileres_fecha_fin on public.alquileres using btree (fecha_fin) TABLESPACE pg_default;

create trigger trigger_actualizar_cantidades_al_devolver
after
update OF estado on alquileres for EACH row when (
  old.estado::text = 'activo'::text
  and new.estado::text = 'devuelto'::text
)
execute FUNCTION actualizar_cantidades_articulo ();

create trigger update_alquileres_updated_at BEFORE
update on alquileres for EACH row
execute FUNCTION update_updated_at_column ();

create table public.articulos (
  id uuid not null default gen_random_uuid (),
  codigo character varying(50) not null,
  nombre character varying(255) not null,
  tipo character varying(50) not null,
  talla character varying(20) null,
  color character varying(50) null,
  precio_alquiler numeric(10, 2) not null,
  precio_venta numeric(10, 2) not null,
  estado character varying(50) null default 'disponible'::character varying,
  fecha_disponible timestamp with time zone null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  cantidad integer not null default 1,
  cantidad_disponible integer not null default 1,
  cantidad_alquilada integer not null default 0,
  cantidad_mantenimiento integer not null default 0,
  cantidad_vendida integer not null default 0,
  cantidad_perdida integer not null default 0,
  constraint articulos_pkey primary key (id),
  constraint articulos_codigo_key unique (codigo)
) TABLESPACE pg_default;

create index IF not exists idx_articulos_estado on public.articulos using btree (estado) TABLESPACE pg_default;

create index IF not exists idx_articulos_tipo on public.articulos using btree (tipo) TABLESPACE pg_default;

create index IF not exists idx_articulos_codigo on public.articulos using btree (codigo) TABLESPACE pg_default;

create trigger update_articulos_updated_at BEFORE
update on articulos for EACH row
execute FUNCTION update_updated_at_column ();

create table public.citas (
  id uuid not null default gen_random_uuid (),
  cliente_id uuid null,
  fecha_hora timestamp with time zone not null,
  descripcion text null,
  estado character varying(50) null default 'pendiente'::character varying,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  tipo character varying(50) not null default 'alquiler'::character varying,
  constraint citas_pkey primary key (id),
  constraint citas_cliente_id_fkey foreign KEY (cliente_id) references clientes (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_citas_estado on public.citas using btree (estado) TABLESPACE pg_default;

create index IF not exists idx_citas_cliente_id on public.citas using btree (cliente_id) TABLESPACE pg_default;

create index IF not exists idx_citas_fecha_hora on public.citas using btree (fecha_hora) TABLESPACE pg_default;

create trigger update_citas_updated_at BEFORE
update on citas for EACH row
execute FUNCTION update_updated_at_column ();

create table public.clientes (
  id uuid not null default gen_random_uuid (),
  dni character varying(20) not null,
  nombre character varying(255) not null,
  telefono character varying(20) not null,
  email character varying(255) null,
  descripcion text null,
  en_papelera boolean null default false,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint clientes_pkey primary key (id),
  constraint clientes_dni_key unique (dni)
) TABLESPACE pg_default;

create index IF not exists idx_clientes_dni on public.clientes using btree (dni) TABLESPACE pg_default;

create index IF not exists idx_clientes_papelera on public.clientes using btree (en_papelera) TABLESPACE pg_default;

create index IF not exists idx_clientes_nombre on public.clientes using btree (nombre) TABLESPACE pg_default;

create trigger update_clientes_updated_at BEFORE
update on clientes for EACH row
execute FUNCTION update_updated_at_column ();

create table public.configuracion (
  id uuid not null default gen_random_uuid (),
  nombre_empleado character varying(255) null default 'Empleado'::character varying,
  tema_oscuro boolean null default false,
  garantia_default numeric(10, 2) null default 50.0,
  mora_diaria numeric(10, 2) null default 10.0,
  dias_maximos_mora integer null default 7,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint configuracion_pkey primary key (id)
) TABLESPACE pg_default;

create trigger update_configuracion_updated_at BEFORE
update on configuracion for EACH row
execute FUNCTION update_updated_at_column ();

create table public.traje_articulos (
  id uuid not null default gen_random_uuid (),
  traje_id uuid null,
  articulo_id uuid null,
  constraint traje_articulos_pkey primary key (id),
  constraint traje_articulos_traje_id_articulo_id_key unique (traje_id, articulo_id),
  constraint traje_articulos_articulo_id_fkey foreign KEY (articulo_id) references articulos (id) on delete CASCADE,
  constraint traje_articulos_traje_id_fkey foreign KEY (traje_id) references trajes (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.trajes (
  id uuid not null default gen_random_uuid (),
  nombre character varying(255) not null,
  descripcion text null,
  created_at timestamp with time zone null default now(),
  constraint trajes_pkey primary key (id)
) TABLESPACE pg_default;

create table public.venta_articulos (
  id uuid not null default gen_random_uuid (),
  venta_id uuid null,
  articulo_id uuid null,
  precio numeric(10, 2) not null,
  created_at timestamp with time zone null default now(),
  cantidad integer not null default 1,
  constraint venta_articulos_pkey primary key (id),
  constraint venta_articulos_articulo_id_fkey foreign KEY (articulo_id) references articulos (id) on delete RESTRICT,
  constraint venta_articulos_venta_id_fkey foreign KEY (venta_id) references ventas (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger trigger_actualizar_cantidades_venta
after INSERT
or DELETE
or
update on venta_articulos for EACH row
execute FUNCTION actualizar_cantidades_articulo ();

create trigger trigger_actualizar_inventario_venta
after INSERT on venta_articulos for EACH row
execute FUNCTION actualizar_inventario_venta ();

create table public.ventas (
  id uuid not null default gen_random_uuid (),
  cliente_id uuid null,
  total numeric(10, 2) not null,
  metodo_pago character varying(50) not null,
  estado character varying(50) null default 'completada'::character varying,
  fecha_devolucion timestamp with time zone null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint ventas_pkey primary key (id),
  constraint ventas_cliente_id_fkey foreign KEY (cliente_id) references clientes (id) on delete RESTRICT
) TABLESPACE pg_default;

create index IF not exists idx_ventas_cliente on public.ventas using btree (cliente_id) TABLESPACE pg_default;

create index IF not exists idx_ventas_estado on public.ventas using btree (estado) TABLESPACE pg_default;

create index IF not exists idx_ventas_created on public.ventas using btree (created_at) TABLESPACE pg_default;

create trigger trigger_restaurar_inventario_devolucion
after
update on ventas for EACH row
execute FUNCTION restaurar_inventario_devolucion ();

create trigger update_ventas_updated_at BEFORE
update on ventas for EACH row
execute FUNCTION update_updated_at_column ();



-- Funciones


DECLARE
  v_articulo_id UUID;
  v_alquiler_id UUID;
BEGIN
  -- Determinar el articulo_id según la tabla que disparó el trigger
  IF TG_TABLE_NAME = 'alquiler_articulos' THEN
    v_articulo_id := COALESCE(NEW.articulo_id, OLD.articulo_id);
    
  ELSIF TG_TABLE_NAME = 'venta_articulos' THEN
    v_articulo_id := COALESCE(NEW.articulo_id, OLD.articulo_id);
    
  ELSIF TG_TABLE_NAME = 'alquileres' THEN
    -- Si el trigger viene de alquileres, actualizar todos los artículos del alquiler
    v_alquiler_id := COALESCE(NEW.id, OLD.id);
    
    -- Actualizar cada artículo del alquiler
    FOR v_articulo_id IN 
      SELECT DISTINCT articulo_id 
      FROM alquiler_articulos 
      WHERE alquiler_id = v_alquiler_id
    LOOP
      -- Recalcular cantidades para este artículo
      UPDATE articulos a
      SET 
        -- cantidad_alquilada = cuántos están activamente alquilados
        cantidad_alquilada = COALESCE((
          SELECT COUNT(*) 
          FROM alquiler_articulos aa
          JOIN alquileres al ON aa.alquiler_id = al.id
          WHERE aa.articulo_id = a.id 
            AND al.estado = 'activo'
        ), 0),
        
        -- cantidad_disponible = total - alquilados - mantenimiento - vendidos - perdidos
        cantidad_disponible = a.cantidad - COALESCE((
          SELECT COUNT(*) 
          FROM alquiler_articulos aa
          JOIN alquileres al ON aa.alquiler_id = al.id
          WHERE aa.articulo_id = a.id 
            AND al.estado = 'activo'
        ), 0) - a.cantidad_mantenimiento - a.cantidad_vendida - a.cantidad_perdida
      WHERE a.id = v_articulo_id;
    END LOOP;
    
    RETURN NEW;
  END IF;
  
  -- Recalcular cantidades para el artículo específico
  IF v_articulo_id IS NOT NULL THEN
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
    WHERE a.id = v_articulo_id;
  END IF;
  
  RETURN NEW;
END;


BEGIN
    -- Verificar que hay suficiente cantidad disponible
    IF (SELECT cantidad_disponible FROM articulos WHERE id = NEW.articulo_id) < NEW.cantidad THEN
        RAISE EXCEPTION 'No hay suficiente inventario disponible para el artículo';
    END IF;
    
    -- Actualizar cantidades en articulos
    UPDATE articulos
    SET 
        cantidad_disponible = cantidad_disponible - NEW.cantidad,
        cantidad_vendida = cantidad_vendida + NEW.cantidad,
        updated_at = NOW()
    WHERE id = NEW.articulo_id;
    
    RETURN NEW;
END;


declare
    v_settings app_settings;
    v_rental record;
    v_days integer;
    v_extra numeric(10,2);
begin
    select * into v_settings from app_settings where id = 1;
    for v_rental in
        select * from rentals
        where estado = 'ACTIVO'
          and fecha_fin < current_date
    loop
        v_days := (current_date - v_rental.fecha_fin);
        v_extra := v_days * v_settings.mora_diaria;
        update rentals
        set mora_acumulada = v_extra,
            updated_at = now()
        where id = v_rental.id;

        if v_days >= v_settings.dias_max_mora then
            update rentals set estado = 'INCUMPLIDO' where id = v_rental.id;
        end if;
    end loop;
end;


declare
    v_article uuid;
    v_hours integer;
    v_reason maintenance_reason;
begin
    select article_id into v_article from rental_items where id = p_item;
    if not found then
        raise exception 'Artículo no encontrado en alquiler';
    end if;

    update rental_items
    set estado = p_estado,
        garantia_retenida = p_reten_g,
        comentario = p_comentario
    where id = p_item;

    if p_estado = 'COMPLETO' then
        select mantenimiento_horas_completo into v_hours from app_settings where id = 1;
        v_reason := 'DEVOLUCION_COMPLETA';
        perform fn_set_article_state(v_article, 'MANTENIMIENTO', v_hours, v_reason, p_comentario);
    elsif p_estado = 'DANADO' then
        select mantenimiento_horas_danado into v_hours from app_settings where id = 1;
        v_reason := 'DEVOLUCION_DANADA';
        perform fn_set_article_state(v_article, 'MANTENIMIENTO', v_hours, v_reason, p_comentario);
    elsif p_estado = 'PERDIDO' then
        perform fn_set_article_state(v_article, 'PERDIDO', null, 'DEVOLUCION_PERDIDA', p_comentario);
    end if;

    if coalesce(p_reten_g,0) > 0 then
        insert into guarantee_actions(rental_item_id, tipo, monto, descripcion)
        values (p_item, 'RETENCION', p_reten_g, p_comentario);
    end if;
end;


begin
    if p_tipo = 'ALQUILERES' or p_tipo = 'AMBOS' then
        return query
        select r.codigo,
               c.dni,
               c.nombres,
               r.created_at,
               r.monto_total + r.mora_acumulada + coalesce(sum(ga.monto),0) as monto,
               jsonb_agg(jsonb_build_object('articulo', ri.descripcion_snapshot, 'estado', ri.estado)) as detalle,
               'ALQUILER' as origen
        from rentals r
        join clients c on c.dni = r.cliente_dni
        left join rental_items ri on ri.rental_id = r.id
        left join guarantee_actions ga on ga.rental_item_id = ri.id
        where r.created_at::date between p_inicio and p_fin
        group by r.id, c.dni;
    end if;

    if p_tipo = 'VENTAS' or p_tipo = 'AMBOS' then
        return query
        select s.codigo,
               c.dni,
               c.nombres,
               s.fecha,
               s.monto_total as monto,
               jsonb_agg(jsonb_build_object('articulo', si.descripcion_snapshot, 'precio', si.precio)) as detalle,
               'VENTA' as origen
        from sales s
        join clients c on c.dni = s.cliente_dni
        left join sale_items si on si.sale_id = s.id
        where s.fecha::date between p_inicio and p_fin
        group by s.id, c.dni;
    end if;
end;



begin
    perform fn_set_article_state(p_article, 'MANTENIMIENTO', p_hours, coalesce(p_reason,'AJUSTE_MANUAL'), p_comment);
end;



begin
    update articles
    set estado = p_state,
        mantenimiento_hasta = case when p_hours is null then null else now() + (p_hours || ' hours')::interval end,
        updated_at = now()
    where id = p_article;

    insert into article_status_history(article_id, estado, motivo, comentario)
    values (p_article, p_state, p_reason, p_comment);
end;



BEGIN
  UPDATE articulos
  SET estado = 'disponible', fecha_disponible = NULL
  WHERE estado = 'mantenimiento'
    AND fecha_disponible IS NOT NULL
    AND fecha_disponible <= NOW();
END;



declare
    activos integer;
begin
    select count(*) into activos
    from rentals
    where cliente_dni = old.dni
      and estado = 'ACTIVO';
    if activos > 0 then
        raise exception 'Cliente tiene alquileres activos';
    end if;
    insert into clients_trash(dni, nombres, telefono, email, descripcion, deleted_by)
    values (old.dni, old.nombres, old.telefono, old.email, old.descripcion, current_setting('app.current_user_id', true)::uuid);
    return old;
end;



BEGIN
    -- Solo procesar si el estado cambió a 'devuelta'
    IF NEW.estado = 'devuelta' AND OLD.estado != 'devuelta' THEN
        -- Restaurar cantidades de todos los artículos de la venta
        UPDATE articulos a
        SET 
            cantidad_disponible = cantidad_disponible + va.cantidad,
            cantidad_vendida = cantidad_vendida - va.cantidad,
            updated_at = NOW()
        FROM venta_articulos va
        WHERE va.venta_id = NEW.id
        AND a.id = va.articulo_id;
    END IF;
    
    RETURN NEW;
END;



begin
  new.updated_at = now();
  return new;
end;



BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;



