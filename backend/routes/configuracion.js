const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Obtener configuración
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('configuracion')
      .select('*')
      .single();

    if (error && error.code !== 'PGRST116') throw error;
    
    // Si no existe configuración, crear una por defecto
    if (!data) {
      const { data: nuevaConfig, error: createError } = await supabase
        .from('configuracion')
        .insert([{
          nombre_empleado: 'Empleado',
          tema_oscuro: false,
          garantia_default: 50.0,
          mora_diaria: 10.0,
          dias_maximos_mora: 7
        }])
        .select()
        .single();

      if (createError) throw createError;
      return res.json(nuevaConfig);
    }

    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Actualizar configuración
router.put('/', async (req, res) => {
  try {
    const { 
      nombre_empleado, 
      tema_oscuro, 
      garantia_default, 
      mora_diaria, 
      dias_maximos_mora 
    } = req.body;

    // Verificar si existe configuración
    const { data: existente } = await supabase
      .from('configuracion')
      .select('id')
      .single();

    let data, error;

    if (existente) {
      // Actualizar
      const result = await supabase
        .from('configuracion')
        .update({
          nombre_empleado,
          tema_oscuro,
          garantia_default,
          mora_diaria,
          dias_maximos_mora
        })
        .eq('id', existente.id)
        .select()
        .single();

      data = result.data;
      error = result.error;
    } else {
      // Crear
      const result = await supabase
        .from('configuracion')
        .insert([{
          nombre_empleado,
          tema_oscuro,
          garantia_default,
          mora_diaria,
          dias_maximos_mora
        }])
        .select()
        .single();

      data = result.data;
      error = result.error;
    }

    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
