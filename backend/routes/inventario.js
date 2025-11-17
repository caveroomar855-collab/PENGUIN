const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Obtener todos los artículos
router.get('/articulos', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('articulos')
      .select('*')
      .neq('estado', 'vendido')
      .neq('estado', 'perdido')
      .order('tipo', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener artículos por estado
router.get('/articulos/estado/:estado', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('articulos')
      .select('*')
      .eq('estado', req.params.estado)
      .order('tipo', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener todos los trajes
router.get('/trajes', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('trajes')
      .select(`
        *,
        traje_articulos(
          *,
          articulos(*)
        )
      `)
      .order('nombre', { ascending: true });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener traje por ID
router.get('/trajes/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('trajes')
      .select(`
        *,
        traje_articulos(
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

// Crear artículo
router.post('/articulos', async (req, res) => {
  try {
    const { 
      codigo, 
      nombre, 
      tipo, 
      talla, 
      color, 
      precio_alquiler, 
      precio_venta 
    } = req.body;

    const { data, error } = await supabase
      .from('articulos')
      .insert([{
        codigo,
        nombre,
        tipo,
        talla,
        color,
        precio_alquiler,
        precio_venta,
        estado: 'disponible'
      }])
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Actualizar artículo
router.put('/articulos/:id', async (req, res) => {
  try {
    const { 
      codigo, 
      nombre, 
      tipo, 
      talla, 
      color, 
      precio_alquiler, 
      precio_venta 
    } = req.body;

    const { data, error } = await supabase
      .from('articulos')
      .update({
        codigo,
        nombre,
        tipo,
        talla,
        color,
        precio_alquiler,
        precio_venta
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

// Cambiar estado de mantenimiento
router.patch('/articulos/:id/mantenimiento', async (req, res) => {
  try {
    const { estado, horas_mantenimiento, indefinido } = req.body;

    let updateData = { estado };

    if (estado === 'mantenimiento' && !indefinido && horas_mantenimiento) {
      const fecha_disponible = new Date();
      fecha_disponible.setHours(fecha_disponible.getHours() + horas_mantenimiento);
      updateData.fecha_disponible = fecha_disponible.toISOString();
    } else if (estado === 'disponible') {
      updateData.fecha_disponible = null;
    }

    const { data, error } = await supabase
      .from('articulos')
      .update(updateData)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Crear traje
router.post('/trajes', async (req, res) => {
  try {
    const { nombre, descripcion, articulos } = req.body;

    // Crear traje
    const { data: traje, error: trajeError } = await supabase
      .from('trajes')
      .insert([{ nombre, descripcion }])
      .select()
      .single();

    if (trajeError) throw trajeError;

    // Asociar artículos
    if (articulos && articulos.length > 0) {
      const articulosData = articulos.map(art_id => ({
        traje_id: traje.id,
        articulo_id: art_id
      }));

      const { error: articulosError } = await supabase
        .from('traje_articulos')
        .insert(articulosData);

      if (articulosError) throw articulosError;
    }

    res.status(201).json(traje);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
