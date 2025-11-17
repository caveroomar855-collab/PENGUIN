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
      cantidad = 1,
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
        cantidad,
        cantidad_disponible: cantidad,
        cantidad_alquilada: 0,
        cantidad_mantenimiento: 0,
        cantidad_vendida: 0,
        cantidad_perdida: 0,
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

// Cambiar estado de artículo
router.patch('/articulos/:id/estado', async (req, res) => {
  try {
    const { estado, fecha_disponible } = req.body;

    let updateData = { estado };

    // Si se pone en mantenimiento y se especifica fecha
    if (estado === 'mantenimiento' && fecha_disponible) {
      updateData.fecha_disponible = fecha_disponible;
    } 
    // Si se quita de mantenimiento, limpiar fecha
    else if (estado === 'disponible') {
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

// Eliminar artículo
router.delete('/articulos/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('articulos')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Gestionar mantenimiento (cantidades)
router.patch('/articulos/:id/mantenimiento', async (req, res) => {
  try {
    const { cantidad, accion, horas_mantenimiento, indefinido } = req.body;
    // accion: 'agregar' o 'quitar'

    // Obtener artículo actual
    const { data: articulo, error: getError } = await supabase
      .from('articulos')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (getError) throw getError;

    let updateData = {};

    if (accion === 'agregar') {
      // Poner unidades en mantenimiento
      if (articulo.cantidad_disponible < cantidad) {
        return res.status(400).json({ error: 'No hay suficientes unidades disponibles' });
      }
      
      updateData.cantidad_disponible = articulo.cantidad_disponible - cantidad;
      updateData.cantidad_mantenimiento = articulo.cantidad_mantenimiento + cantidad;

      if (!indefinido && horas_mantenimiento) {
        const fecha_disponible = new Date();
        fecha_disponible.setHours(fecha_disponible.getHours() + horas_mantenimiento);
        updateData.fecha_disponible = fecha_disponible.toISOString();
      }
    } else if (accion === 'quitar') {
      // Quitar unidades de mantenimiento
      const cantidadAQuitar = cantidad || articulo.cantidad_mantenimiento;
      
      updateData.cantidad_disponible = articulo.cantidad_disponible + cantidadAQuitar;
      updateData.cantidad_mantenimiento = Math.max(0, articulo.cantidad_mantenimiento - cantidadAQuitar);
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
