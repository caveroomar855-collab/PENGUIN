const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Obtener todos los alquileres activos
router.get('/activos', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('alquileres')
      .select(`
        *,
        clientes(dni, nombre, telefono),
        alquiler_articulos(
          *,
          articulos(*)
        )
      `)
      .eq('estado', 'activo')
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener historial de alquileres
router.get('/historial', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('alquileres')
      .select(`
        *,
        clientes(dni, nombre, telefono),
        alquiler_articulos(
          *,
          articulos(*)
        )
      `)
      .in('estado', ['devuelto', 'perdido'])
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener alquiler por ID
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('alquileres')
      .select(`
        *,
        clientes(dni, nombre, telefono),
        alquiler_articulos(
          *,
          articulos(*)
        )
      `)
      .eq('id', req.params.id)
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Crear alquiler
router.post('/', async (req, res) => {
  try {
    const { 
      cliente_id, 
      articulos, 
      fecha_inicio, 
      fecha_fin, 
      monto_alquiler, 
      garantia, 
      metodo_pago,
      observaciones 
    } = req.body;

    // Crear alquiler
    const { data: alquiler, error: alquilerError } = await supabase
      .from('alquileres')
      .insert([{
        cliente_id,
        fecha_inicio,
        fecha_fin,
        monto_alquiler,
        garantia,
        metodo_pago,
        observaciones: observaciones || null,
        estado: 'activo'
      }])
      .select()
      .single();

    if (alquilerError) throw alquilerError;

    // Insertar artículos del alquiler
    const articulosData = articulos.map(art => ({
      alquiler_id: alquiler.id,
      articulo_id: art.id,
      estado: 'alquilado'
    }));

    const { error: articulosError } = await supabase
      .from('alquiler_articulos')
      .insert(articulosData);

    if (articulosError) throw articulosError;

    // Actualizar estado de artículos a alquilado
    for (const art of articulos) {
      await supabase
        .from('articulos')
        .update({ estado: 'alquilado' })
        .eq('id', art.id);
    }

    res.status(201).json(alquiler);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Marcar devolución
router.post('/:id/devolucion', async (req, res) => {
  try {
    const { articulos, retener_garantia, descripcion_retencion } = req.body;

    // Obtener alquiler
    const { data: alquiler, error: alquilerError } = await supabase
      .from('alquileres')
      .select('*, alquiler_articulos(*)')
      .eq('id', req.params.id)
      .single();

    if (alquilerError) throw alquilerError;

    let garantia_retenida = 0;
    let hay_perdidos = false;

    // Procesar cada artículo
    for (const art of articulos) {
      const { articulo_id, estado_devolucion } = art;

      // Actualizar estado en alquiler_articulos
      await supabase
        .from('alquiler_articulos')
        .update({ estado: estado_devolucion })
        .eq('alquiler_id', req.params.id)
        .eq('articulo_id', articulo_id);

      if (estado_devolucion === 'completo') {
        // Poner en mantenimiento por 24 horas
        const fecha_disponible = new Date();
        fecha_disponible.setHours(fecha_disponible.getHours() + 24);
        
        await supabase
          .from('articulos')
          .update({ 
            estado: 'mantenimiento',
            fecha_disponible: fecha_disponible.toISOString()
          })
          .eq('id', articulo_id);
      } else if (estado_devolucion === 'dañado') {
        // Poner en mantenimiento por 72 horas
        const fecha_disponible = new Date();
        fecha_disponible.setHours(fecha_disponible.getHours() + 72);
        
        await supabase
          .from('articulos')
          .update({ 
            estado: 'mantenimiento',
            fecha_disponible: fecha_disponible.toISOString()
          })
          .eq('id', articulo_id);
      } else if (estado_devolucion === 'perdido') {
        hay_perdidos = true;
        // Marcar como perdido y disminuir inventario
        await supabase
          .from('articulos')
          .update({ estado: 'perdido' })
          .eq('id', articulo_id);
      }
    }

    // Calcular mora si aplica
    let mora_total = 0;
    const fecha_fin = new Date(alquiler.fecha_fin);
    const fecha_devolucion = new Date();
    
    if (fecha_devolucion > fecha_fin) {
      const dias_mora = Math.ceil((fecha_devolucion - fecha_fin) / (1000 * 60 * 60 * 24));
      
      // Obtener configuración de mora
      const { data: config } = await supabase
        .from('configuracion')
        .select('mora_diaria, dias_maximos_mora')
        .single();

      if (config) {
        const dias_a_cobrar = Math.min(dias_mora, config.dias_maximos_mora);
        mora_total = dias_a_cobrar * config.mora_diaria;
      }
    }

    // Si se retiene garantía o hay artículos perdidos
    if (retener_garantia || hay_perdidos) {
      garantia_retenida = alquiler.garantia;
    }

    // Actualizar alquiler
    const { data, error } = await supabase
      .from('alquileres')
      .update({
        estado: 'devuelto',
        fecha_devolucion: new Date().toISOString(),
        mora_cobrada: mora_total,
        garantia_retenida,
        descripcion_retencion: descripcion_retencion || null
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
