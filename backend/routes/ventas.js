const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Obtener todas las ventas
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('ventas')
      .select(`
        *,
        clientes(dni, nombre, telefono),
        venta_articulos(
          *,
          articulos(*)
        )
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener venta por ID
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('ventas')
      .select(`
        *,
        clientes(dni, nombre, telefono),
        venta_articulos(
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

// Crear venta
router.post('/', async (req, res) => {
  try {
    const { 
      cliente_id, 
      articulos, 
      total, 
      metodo_pago 
    } = req.body;

    // Crear venta
    const { data: venta, error: ventaError } = await supabase
      .from('ventas')
      .insert([{
        cliente_id,
        total,
        metodo_pago,
        estado: 'completada'
      }])
      .select()
      .single();

    if (ventaError) throw ventaError;

    // Insertar artículos de la venta
    const articulosData = articulos.map(art => ({
      venta_id: venta.id,
      articulo_id: art.id,
      precio: art.precio_venta
    }));

    const { error: articulosError } = await supabase
      .from('venta_articulos')
      .insert(articulosData);

    if (articulosError) throw articulosError;

    // Actualizar estado de artículos a vendido
    for (const art of articulos) {
      await supabase
        .from('articulos')
        .update({ estado: 'vendido' })
        .eq('id', art.id);
    }

    res.status(201).json(venta);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Procesar devolución (máximo 3 días)
router.post('/:id/devolucion', async (req, res) => {
  try {
    // Obtener venta
    const { data: venta, error: ventaError } = await supabase
      .from('ventas')
      .select('*, venta_articulos(*)')
      .eq('id', req.params.id)
      .single();

    if (ventaError) throw ventaError;

    // Verificar que no hayan pasado más de 3 días
    const fecha_venta = new Date(venta.created_at);
    const fecha_actual = new Date();
    const dias_transcurridos = Math.ceil((fecha_actual - fecha_venta) / (1000 * 60 * 60 * 24));

    if (dias_transcurridos > 3) {
      return res.status(400).json({ 
        error: 'No se puede procesar devolución después de 3 días' 
      });
    }

    // Marcar venta como devuelta
    const { data, error } = await supabase
      .from('ventas')
      .update({
        estado: 'devuelta',
        fecha_devolucion: new Date().toISOString()
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    // Restaurar artículos a disponible
    for (const artVenta of venta.venta_articulos) {
      await supabase
        .from('articulos')
        .update({ estado: 'disponible' })
        .eq('id', artVenta.articulo_id);
    }

    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
