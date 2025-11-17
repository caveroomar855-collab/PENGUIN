-- ============================================================================
-- FIX: Corregir índice de citas para usar fecha_hora en lugar de fecha
-- ============================================================================
-- Este script corrige el índice que estaba usando el campo incorrecto
-- Ejecutar en Supabase SQL Editor
-- ============================================================================

-- Eliminar el índice antiguo incorrecto (si existe)
DROP INDEX IF EXISTS idx_citas_fecha;

-- Crear el índice correcto con fecha_hora
CREATE INDEX IF NOT EXISTS idx_citas_fecha_hora ON citas(fecha_hora);

-- Verificar que el índice se creó correctamente
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'citas'
ORDER BY indexname;

-- ============================================================================
-- ✅ Script completado
-- ============================================================================
-- El índice ahora usa fecha_hora que es el campo correcto de la tabla citas
-- Esto mejorará el rendimiento de las consultas de citas pendientes
-- ============================================================================
