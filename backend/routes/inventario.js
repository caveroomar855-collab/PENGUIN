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
    // Calcular totales por traje (suma de las cantidades de sus artículos)
    const augmented = (data || []).map((traje) => {
      const items = (traje.traje_articulos || []).map((ta) => ta.articulos).filter(Boolean);
      const disponibles = items.reduce((s, a) => s + (a.cantidad_disponible || 0), 0);
      const alquilados = items.reduce((s, a) => s + (a.cantidad_alquilada || 0), 0);
      const mantenimiento = items.reduce((s, a) => s + (a.cantidad_mantenimiento || 0), 0);
      const total = items.reduce((s, a) => s + (a.cantidad || 0), 0);
      return { ...traje, totales: { total, disponibles, alquilados, mantenimiento } };
    });

    res.json(augmented);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Resumen agregado de estados (totales por unidades)
router.get('/estados/summary', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('articulos')
      .select('id, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida');

    if (error) throw error;

    // Cambiar lógica: devolver conteos por artículo (número de rows) en lugar de sumas de unidades
    const rows = data || [];
    const summary = {
      total: rows.length, // número de artículos distintos
      disponibles: rows.filter(a => (a.cantidad_disponible || 0) > 0).length,
      alquilados: rows.filter(a => (a.cantidad_alquilada || 0) > 0).length,
      mantenimiento: rows.filter(a => (a.cantidad_mantenimiento || 0) > 0).length,
      vendidos: rows.filter(a => (a.cantidad_vendida || 0) > 0).length,
      perdidos: rows.filter(a => (a.cantidad_perdida || 0) > 0).length
    };

    res.json(summary);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Lista de artículos por tipo de estado (muestra nombre y cantidad correspondiente)
router.get('/estados/list/:tipo', async (req, res) => {
  try {
    const tipo = req.params.tipo;
    let column;

    switch ((tipo || '').toLowerCase()) {
      case 'disponibles':
        column = 'cantidad_disponible';
        break;
      case 'alquilados':
        column = 'cantidad_alquilada';
        break;
      case 'mantenimiento':
        column = 'cantidad_mantenimiento';
        break;
      case 'vendidos':
        column = 'cantidad_vendida';
        break;
      case 'perdidos':
        column = 'cantidad_perdida';
        break;
      default:
        return res.status(400).json({ error: 'Tipo inválido. Use: disponibles, alquilados, mantenimiento, vendidos, perdidos' });
    }

    // Seleccionar artículos donde la columna correspondiente sea > 0
    const { data, error } = await supabase
      .from('articulos')
      .select(`id, nombre, ${column}`)
      .gt(column, 0)
      .order('nombre', { ascending: true });

    if (error) throw error;

    // Normalizar nombre de campo a 'cantidad'
    const list = (data || []).map(a => ({ id: a.id, nombre: a.nombre, cantidad: a[column] || 0 }));
    res.json(list);
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
      cantidad = 1,
      precio_alquiler,
      precio_venta
    } = req.body;

    // If codigo not provided (client removed the field), generate an automatic code
    const codigoFinal = codigo || `AUTO-${Date.now().toString(36)}`;

    const { data, error } = await supabase
      .from('articulos')
      .insert([{
        codigo: codigoFinal,
        nombre,
        tipo,
        talla,
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
      precio_alquiler,
      precio_venta,
      cantidad
    } = req.body;

    // Obtener artículo actual para calcular deltas
    const { data: articulo, error: getErr } = await supabase
      .from('articulos')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (getErr) throw getErr;

    // Si se envía cantidad y es <= 0, eliminar el artículo
    if (typeof cantidad !== 'undefined' && Number(cantidad) <= 0) {
      const { error: delErr } = await supabase
        .from('articulos')
        .delete()
        .eq('id', req.params.id);
      if (delErr) throw delErr;
      return res.json({ deleted: true });
    }

    const updateData = {};
    if (typeof codigo !== 'undefined') updateData.codigo = codigo;
    if (typeof nombre !== 'undefined') updateData.nombre = nombre;
    if (typeof tipo !== 'undefined') updateData.tipo = tipo;
    if (typeof talla !== 'undefined') updateData.talla = talla;
    if (typeof precio_alquiler !== 'undefined') updateData.precio_alquiler = precio_alquiler;
    if (typeof precio_venta !== 'undefined') updateData.precio_venta = precio_venta;

    if (typeof cantidad !== 'undefined') {
      const nueva = Number(cantidad);
      const actual = articulo.cantidad || 0;
      const delta = nueva - actual;

      updateData.cantidad = nueva;
      // Ajustar cantidad_disponible con la misma diferencia (no bajar por debajo de 0)
      updateData.cantidad_disponible = Math.max(0, (articulo.cantidad_disponible || 0) + delta);
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
