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
    const articulosData = [];

    // Validar disponibilidad por artículo antes de insertar
    for (const art of articulos) {
      const articuloId = art.id || art.articulo_id || art.articuloId;
      if (!articuloId) {
        throw new Error('Artículo sin id en payload');
      }
      const qty = Math.max(1, parseInt(art.cantidad || art.qty || 1, 10));

      // Consultar disponibilidad actual
      const { data: articuloDB, error: artError } = await supabase
        .from('articulos')
        .select('cantidad_disponible, cantidad')
        .eq('id', articuloId)
        .single();

      if (artError) {
        console.error('Error leyendo artículo', articuloId, artError);
        throw artError;
      }

      const disponible = articuloDB?.cantidad_disponible ?? articuloDB?.cantidad ?? 0;
      if (qty > disponible) {
        return res.status(400).json({ error: `No hay suficiente stock para el artículo ${articuloId}. Disponible: ${disponible}, solicitado: ${qty}` });
      }

      for (let i = 0; i < qty; i++) {
        articulosData.push({
          alquiler_id: alquiler.id,
          articulo_id: articuloId,
          estado: 'alquilado'
        });
      }
    }

    console.log('Insertando artículos (expanded by cantidad):', articulosData.length, 'rows');

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

    // Determinar si hay artículos marcados como perdidos en el payload
    const hay_perdidos = Array.isArray(articulos) && articulos.some(a => String(a.estado_devolucion).toLowerCase() === 'perdido');

    // Calcular mora (igual lógica que antes)
    let mora_total = 0;
    const fecha_fin = new Date(alquiler.fecha_fin);
    const fecha_devolucion = new Date();
    if (fecha_devolucion > fecha_fin) {
      const dias_mora = Math.ceil((fecha_devolucion - fecha_fin) / (1000 * 60 * 60 * 24));
      const { data: config } = await supabase
        .from('configuracion')
        .select('mora_diaria, dias_maximos_mora')
        .single();
      if (config) {
        const dias_a_cobrar = Math.min(dias_mora, config.dias_maximos_mora);
        mora_total = dias_a_cobrar * config.mora_diaria;
      }
    }

    if (retener_garantia || hay_perdidos) {
      garantia_retenida = alquiler.garantia;
    }

    // Llamada RPC atómica en la base para procesar la devolución
    console.log('Llamando RPC fn_procesar_devolucion_safe para alquiler:', req.params.id);
    console.log('Payload RPC p_articulos (object):', articulos);
    const { data: rpcData, error: rpcError } = await supabase
      .rpc('fn_procesar_devolucion_safe', {
        p_alquiler: req.params.id,
        // pasar como JSON/Array para que Supabase lo reciba como jsonb, NO como string
        p_articulos: articulos,
        p_mora: mora_total,
        p_garantia_retenida: garantia_retenida,
        p_descripcion: descripcion_retencion || null
      });

    if (rpcError) {
      console.error('Error RPC fn_procesar_devolucion:', rpcError);
      throw rpcError;
    }

    // Recuperar alquiler actualizado para devolver al cliente
    const { data: updatedAlquiler, error: updatedError } = await supabase
      .from('alquileres')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (updatedError) throw updatedError;

    console.log('✅ Devolución procesada vía RPC correctamente');
    res.json(updatedAlquiler);

    // NOTA: el flujo retorna dentro del bloque anterior tras la llamada RPC
  } catch (error) {
    console.error('❌ Error en devolución:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
