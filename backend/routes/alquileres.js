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
    console.log('=== CREAR ALQUILER ===');
    console.log('Body recibido:', JSON.stringify(req.body, null, 2));
    
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

    console.log('Artículos a alquilar:', articulos);

    // Crear alquiler
    const { data: alquiler, error: alquilerError } = await supabase
      .from('alquileres')
      .insert([{
        cliente_id,
        fecha_inicio,
        fecha_fin,
        monto_alquiler,
        garantia,
        metodo_pago: metodo_pago || 'efectivo',
        observaciones: observaciones || null,
        estado: 'activo'
      }])
      .select()
      .single();

    if (alquilerError) {
      console.error('Error creando alquiler:', alquilerError);
      throw alquilerError;
    }
    
    console.log('Alquiler creado:', alquiler.id);

    // Insertar artículos del alquiler
    const articulosData = articulos.map(art => ({
      alquiler_id: alquiler.id,
      articulo_id: art.id,
      estado: 'alquilado'
    }));

    console.log('Insertando artículos:', articulosData);

    const { error: articulosError } = await supabase
      .from('alquiler_articulos')
      .insert(articulosData);

    if (articulosError) {
      console.error('Error insertando artículos:', articulosError);
      throw articulosError;
    }

    console.log('Alquiler creado exitosamente');
    // Las cantidades se actualizan automáticamente con el trigger
    // No es necesario actualizar el estado individual

    res.status(201).json(alquiler);
  } catch (error) {
    console.error('ERROR GENERAL:', error.message);
    console.error('Stack:', error.stack);
    res.status(500).json({ error: error.message });
  }
});

// Marcar devolución
router.post('/:id/devolucion', async (req, res) => {
  try {
    const { articulos, retener_garantia, descripcion_retencion } = req.body;

    console.log('=== PROCESAR DEVOLUCIÓN ===');
    console.log('Alquiler ID:', req.params.id);
    console.log('Artículos a devolver:', articulos);

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

      console.log(`Procesando artículo ${articulo_id}: ${estado_devolucion}`);

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
        
        console.log(`  → Mantenimiento 24h hasta ${fecha_disponible}`);
        
        // Incrementar cantidad_mantenimiento y actualizar estado
        const { data: articulo } = await supabase
          .from('articulos')
          .select('cantidad_mantenimiento')
          .eq('id', articulo_id)
          .single();

        await supabase
          .from('articulos')
          .update({ 
            estado: 'mantenimiento',
            fecha_disponible: fecha_disponible.toISOString(),
            cantidad_mantenimiento: (articulo?.cantidad_mantenimiento || 0) + 1
          })
          .eq('id', articulo_id);

      } else if (estado_devolucion === 'dañado') {
        // Poner en mantenimiento por 72 horas
        const fecha_disponible = new Date();
        fecha_disponible.setHours(fecha_disponible.getHours() + 72);
        
        console.log(`  → Mantenimiento 72h (dañado) hasta ${fecha_disponible}`);
        
        // Incrementar cantidad_mantenimiento
        const { data: articulo } = await supabase
          .from('articulos')
          .select('cantidad_mantenimiento')
          .eq('id', articulo_id)
          .single();

        await supabase
          .from('articulos')
          .update({ 
            estado: 'mantenimiento',
            fecha_disponible: fecha_disponible.toISOString(),
            cantidad_mantenimiento: (articulo?.cantidad_mantenimiento || 0) + 1
          })
          .eq('id', articulo_id);

      } else if (estado_devolucion === 'perdido') {
        hay_perdidos = true;
        console.log(`  → Artículo PERDIDO`);
        
        // Incrementar cantidad_perdida
        const { data: articulo } = await supabase
          .from('articulos')
          .select('cantidad_perdida')
          .eq('id', articulo_id)
          .single();

        await supabase
          .from('articulos')
          .update({ 
            estado: 'perdido',
            cantidad_perdida: (articulo?.cantidad_perdida || 0) + 1
          })
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

    // IMPORTANTE: Actualizar el estado del alquiler a 'devuelto'
    // Esto hace que el trigger recalcule cantidad_alquilada correctamente
    console.log('Actualizando alquiler a estado: devuelto');
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
    
    console.log('✅ Devolución completada exitosamente');
    console.log('Estado alquiler:', data.estado);
    
    res.json(data);
  } catch (error) {
    console.error('❌ Error en devolución:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
