const express = require('express');
const router = express.Router();
const supabase = require('../config/database');

// Obtener resumen del día
router.get('/resumen-dia', async (req, res) => {
  try {
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    const manana = new Date(hoy);
    manana.setDate(manana.getDate() + 1);

    // Alquileres activos
    const { data: alquileres, error: alquileresError } = await supabase
      .from('alquileres')
      .select('*')
      .eq('estado', 'activo');

    if (alquileresError) throw alquileresError;

    // Ganancias de alquileres del día
    const { data: alquileresHoy, error: alquileresHoyError } = await supabase
      .from('alquileres')
      .select('monto_alquiler, garantia_retenida, mora_cobrada')
      .gte('created_at', hoy.toISOString())
      .lt('created_at', manana.toISOString());

    if (alquileresHoyError) throw alquileresHoyError;

    const ganancias_alquileres = alquileresHoy.reduce((sum, a) => 
      sum + (a.monto_alquiler || 0) + (a.garantia_retenida || 0) + (a.mora_cobrada || 0), 0
    );

    // Ganancias de ventas del día
    const { data: ventasHoy, error: ventasHoyError } = await supabase
      .from('ventas')
      .select('total')
      .eq('estado', 'completada')
      .gte('created_at', hoy.toISOString())
      .lt('created_at', manana.toISOString());

    if (ventasHoyError) throw ventasHoyError;

    const ganancias_ventas = ventasHoy.reduce((sum, v) => sum + (v.total || 0), 0);

    // Citas pendientes (si las hay)
    const { data: citas, error: citasError } = await supabase
      .from('citas')
      .select('*')
      .eq('estado', 'pendiente')
      .gte('fecha_hora', hoy.toISOString());

    res.json({
      alquileres_activos: alquileres?.length || 0,
      citas_pendientes: citas?.length || 0,
      ganancias_alquileres,
      ganancias_ventas,
      ganancia_total: ganancias_alquileres + ganancias_ventas
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Generar reporte de alquileres por rango de fechas
router.post('/alquileres', async (req, res) => {
  try {
    const { fecha_inicio, fecha_fin } = req.body;

    const { data, error } = await supabase
      .from('alquileres')
      .select(`
        *,
        clientes(dni, nombre),
        alquiler_articulos(
          articulos(nombre, codigo)
        )
      `)
      .gte('created_at', fecha_inicio)
      .lte('created_at', fecha_fin)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Calcular totales
    const total_alquileres = data.length;
    const total_ingresos = data.reduce((sum, a) => 
      sum + (a.monto_alquiler || 0) + (a.garantia_retenida || 0) + (a.mora_cobrada || 0), 0
    );

    res.json({
      alquileres: data,
      total_alquileres,
      total_ingresos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Generar reporte de ventas por rango de fechas
router.post('/ventas', async (req, res) => {
  try {
    const { fecha_inicio, fecha_fin } = req.body;

    const { data, error } = await supabase
      .from('ventas')
      .select(`
        *,
        clientes(dni, nombre),
        venta_articulos(
          articulos(nombre, codigo),
          precio
        )
      `)
      .eq('estado', 'completada')
      .gte('created_at', fecha_inicio)
      .lte('created_at', fecha_fin)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // Calcular totales
    const total_ventas = data.length;
    const total_ingresos = data.reduce((sum, v) => sum + (v.total || 0), 0);

    res.json({
      ventas: data,
      total_ventas,
      total_ingresos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Generar reporte de inventario (actual)
router.post('/inventario', async (req, res) => {
  try {
    // Para inventario no usamos fecha_inicio/fin; devolvemos el estado actual
    const { data, error } = await supabase
      .from('articulos')
      .select('id, nombre, tipo, talla, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento')
      .order('nombre', { ascending: true });

    if (error) throw error;

    // Calcular totales simples
    const total_articulos = (data || []).length;
    const total_unidades = (data || []).reduce((sum, a) => sum + (a.cantidad || 0), 0);

    res.json({ articulos: data, total_articulos, total_unidades });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
