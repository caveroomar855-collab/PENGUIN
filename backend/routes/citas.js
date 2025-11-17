const express = require('express');
const router = express.Router();
const { supabase } = require('../database/supabase');

// Obtener todas las citas
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('citas')
      .select('*, clientes(dni, nombre, telefono)')
      .order('fecha_hora', { ascending: true });

    if (error) throw error;
    res.json(data || []);
  } catch (error) {
    console.error('Error obteniendo citas:', error);
    res.status(500).json({ error: 'Error obteniendo citas' });
  }
});

// Obtener citas pendientes
router.get('/pendientes', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('citas')
      .select('*, clientes(dni, nombre, telefono)')
      .eq('estado', 'pendiente')
      .gte('fecha_hora', new Date().toISOString())
      .order('fecha_hora', { ascending: true });

    if (error) throw error;
    res.json(data || []);
  } catch (error) {
    console.error('Error obteniendo citas pendientes:', error);
    res.status(500).json({ error: 'Error obteniendo citas pendientes' });
  }
});

// Crear nueva cita
router.post('/', async (req, res) => {
  try {
    const { cliente_id, fecha_hora, tipo, descripcion } = req.body;

    if (!cliente_id || !fecha_hora || !tipo) {
      return res.status(400).json({ 
        error: 'Cliente, fecha/hora y tipo son obligatorios' 
      });
    }

    const { data, error } = await supabase
      .from('citas')
      .insert([{
        cliente_id,
        fecha_hora,
        tipo,
        descripcion,
        estado: 'pendiente'
      }])
      .select('*, clientes(dni, nombre, telefono)')
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    console.error('Error creando cita:', error);
    res.status(500).json({ error: 'Error creando cita' });
  }
});

// Actualizar estado de cita
router.patch('/:id/estado', async (req, res) => {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!['pendiente', 'completada', 'cancelada'].includes(estado)) {
      return res.status(400).json({ error: 'Estado inválido' });
    }

    const { data, error } = await supabase
      .from('citas')
      .update({ estado })
      .eq('id', id)
      .select('*, clientes(dni, nombre, telefono)')
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('Error actualizando cita:', error);
    res.status(500).json({ error: 'Error actualizando cita' });
  }
});

// Eliminar cita
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('citas')
      .delete()
      .eq('id', id);

    if (error) throw error;
    res.json({ message: 'Cita eliminada exitosamente' });
  } catch (error) {
    console.error('Error eliminando cita:', error);
    res.status(500).json({ error: 'Error eliminando cita' });
  }
});

module.exports = router;
