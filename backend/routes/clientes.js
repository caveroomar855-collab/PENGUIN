const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Obtener todos los clientes (excluyendo papelera)
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('en_papelera', false)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Obtener clientes en papelera
router.get('/papelera', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('en_papelera', true)
      .order('updated_at', { ascending: false });

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Buscar cliente por DNI
router.get('/dni/:dni', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('dni', req.params.dni)
      .single();

    if (error && error.code !== 'PGRST116') throw error;
    res.json(data || null);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Crear cliente
router.post('/', async (req, res) => {
  try {
    const { dni, nombre, telefono, email, descripcion } = req.body;

    // Verificar DNI duplicado
    const { data: existente } = await supabase
      .from('clientes')
      .select('dni, nombre')
      .eq('dni', dni)
      .single();

    if (existente) {
      return res.status(400).json({ 
        error: 'DNI duplicado', 
        cliente_existente: existente 
      });
    }

    const { data, error } = await supabase
      .from('clientes')
      .insert([{
        dni,
        nombre,
        telefono,
        email: email || null,
        descripcion: descripcion || null,
        en_papelera: false
      }])
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Actualizar cliente
router.put('/:id', async (req, res) => {
  try {
    const { dni, nombre, telefono, email, descripcion } = req.body;

    // Verificar DNI duplicado (excluyendo el mismo cliente)
    const { data: existente } = await supabase
      .from('clientes')
      .select('id, dni, nombre')
      .eq('dni', dni)
      .neq('id', req.params.id)
      .single();

    if (existente) {
      return res.status(400).json({ 
        error: 'DNI duplicado', 
        cliente_existente: existente 
      });
    }

    const { data, error } = await supabase
      .from('clientes')
      .update({
        dni,
        nombre,
        telefono,
        email,
        descripcion,
        updated_at: new Date().toISOString()
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

// Enviar a papelera
router.patch('/:id/papelera', async (req, res) => {
  try {
    // Verificar si tiene alquileres activos
    const { data: alquileres, error: alquilerError } = await supabase
      .from('alquileres')
      .select('id')
      .eq('cliente_id', req.params.id)
      .eq('estado', 'activo');

    if (alquilerError) throw alquilerError;

    if (alquileres && alquileres.length > 0) {
      return res.status(400).json({ 
        error: 'No se puede enviar a papelera un cliente con alquileres activos' 
      });
    }

    const { data, error } = await supabase
      .from('clientes')
      .update({
        en_papelera: true,
        updated_at: new Date().toISOString()
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

// Restaurar de papelera
router.patch('/:id/restaurar', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .update({
        en_papelera: false,
        updated_at: new Date().toISOString()
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

// Eliminar permanentemente
router.delete('/:id', async (req, res) => {
  try {
    const { error } = await supabase
      .from('clientes')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ message: 'Cliente eliminado permanentemente' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
