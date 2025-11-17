-- ============================================================================
-- DATOS DE PRUEBA - PENGUIN TERNOS
-- ============================================================================
-- Este script crea clientes, artículos y trajes de prueba
-- Ejecutar en Supabase SQL Editor
-- ============================================================================

-- PASO 1: CREAR CLIENTES
-- 9 clientes con DNI repetido (11111111, 22222222, etc.)
INSERT INTO clientes (dni, nombre, telefono, email) VALUES
('11111111', 'Juan Pérez García', '987654321', 'juan.perez@email.com'),
('22222222', 'María González López', '987654322', 'maria.gonzalez@email.com'),
('33333333', 'Carlos Rodríguez Sánchez', '987654323', 'carlos.rodriguez@email.com'),
('44444444', 'Ana Martínez Fernández', '987654324', 'ana.martinez@email.com'),
('55555555', 'Luis Torres Ramírez', '987654325', 'luis.torres@email.com'),
('66666666', 'Carmen Flores Morales', '987654326', 'carmen.flores@email.com'),
('77777777', 'Pedro Vargas Castro', '987654327', 'pedro.vargas@email.com'),
('88888888', 'Isabel Romero Ortiz', '987654328', 'isabel.romero@email.com'),
('99999999', 'Roberto Silva Mendoza', '987654329', 'roberto.silva@email.com')
ON CONFLICT (dni) DO NOTHING;

-- PASO 2: CREAR ARTÍCULOS
-- 5 Sacos (códigos 1001-1005)
INSERT INTO articulos (codigo, nombre, tipo, talla, color, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida, precio_alquiler, precio_venta, estado) VALUES
('1001', 'Saco Ejecutivo Negro', 'saco', 'M', 'Negro', 3, 3, 0, 0, 0, 0, 25.00, 150.00, 'disponible'),
('1002', 'Saco Clásico Azul Marino', 'saco', 'L', 'Azul', 3, 3, 0, 0, 0, 0, 25.00, 150.00, 'disponible'),
('1003', 'Saco Moderno Gris', 'saco', 'M', 'Gris', 3, 3, 0, 0, 0, 0, 25.00, 150.00, 'disponible'),
('1004', 'Saco Elegante Negro', 'saco', 'S', 'Negro', 3, 3, 0, 0, 0, 0, 25.00, 150.00, 'disponible'),
('1005', 'Saco Premium Azul', 'saco', 'XL', 'Azul', 3, 3, 0, 0, 0, 0, 30.00, 180.00, 'disponible')
ON CONFLICT (codigo) DO NOTHING;

-- 5 Chalecos (códigos 2001-2005)
INSERT INTO articulos (codigo, nombre, tipo, talla, color, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida, precio_alquiler, precio_venta, estado) VALUES
('2001', 'Chaleco Ejecutivo Negro', 'chaleco', 'M', 'Negro', 3, 3, 0, 0, 0, 0, 15.00, 80.00, 'disponible'),
('2002', 'Chaleco Clásico Azul', 'chaleco', 'L', 'Azul', 3, 3, 0, 0, 0, 0, 15.00, 80.00, 'disponible'),
('2003', 'Chaleco Moderno Gris', 'chaleco', 'M', 'Gris', 3, 3, 0, 0, 0, 0, 15.00, 80.00, 'disponible'),
('2004', 'Chaleco Elegante Negro', 'chaleco', 'S', 'Negro', 3, 3, 0, 0, 0, 0, 15.00, 80.00, 'disponible'),
('2005', 'Chaleco Premium Azul', 'chaleco', 'XL', 'Azul', 3, 3, 0, 0, 0, 0, 18.00, 90.00, 'disponible')
ON CONFLICT (codigo) DO NOTHING;

-- 5 Corbatas (códigos 3001-3005)
INSERT INTO articulos (codigo, nombre, tipo, talla, color, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida, precio_alquiler, precio_venta, estado) VALUES
('3001', 'Corbata Seda Negra', 'extra', 'Única', 'Negro', 5, 5, 0, 0, 0, 0, 5.00, 25.00, 'disponible'),
('3002', 'Corbata Elegante Azul', 'extra', 'Única', 'Azul', 5, 5, 0, 0, 0, 0, 5.00, 25.00, 'disponible'),
('3003', 'Corbata Moderna Gris', 'extra', 'Única', 'Gris', 5, 5, 0, 0, 0, 0, 5.00, 25.00, 'disponible'),
('3004', 'Corbata Rayas Negras', 'extra', 'Única', 'Negro', 5, 5, 0, 0, 0, 0, 5.00, 25.00, 'disponible'),
('3005', 'Corbata Premium Azul', 'extra', 'Única', 'Azul', 5, 5, 0, 0, 0, 0, 7.00, 30.00, 'disponible')
ON CONFLICT (codigo) DO NOTHING;

-- 5 Pantalones (códigos 4001-4005)
INSERT INTO articulos (codigo, nombre, tipo, talla, color, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida, precio_alquiler, precio_venta, estado) VALUES
('4001', 'Pantalón Vestir Negro', 'pantalon', '32', 'Negro', 3, 3, 0, 0, 0, 0, 20.00, 100.00, 'disponible'),
('4002', 'Pantalón Clásico Azul', 'pantalon', '34', 'Azul', 3, 3, 0, 0, 0, 0, 20.00, 100.00, 'disponible'),
('4003', 'Pantalón Moderno Gris', 'pantalon', '32', 'Gris', 3, 3, 0, 0, 0, 0, 20.00, 100.00, 'disponible'),
('4004', 'Pantalón Elegante Negro', 'pantalon', '30', 'Negro', 3, 3, 0, 0, 0, 0, 20.00, 100.00, 'disponible'),
('4005', 'Pantalón Premium Azul', 'pantalon', '36', 'Azul', 3, 3, 0, 0, 0, 0, 22.00, 120.00, 'disponible')
ON CONFLICT (codigo) DO NOTHING;

-- 5 Camisas (códigos 5001-5005)
INSERT INTO articulos (codigo, nombre, tipo, talla, color, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida, precio_alquiler, precio_venta, estado) VALUES
('5001', 'Camisa Ejecutiva Blanca', 'camisa', 'M', 'Blanco', 4, 4, 0, 0, 0, 0, 12.00, 60.00, 'disponible'),
('5002', 'Camisa Clásica Celeste', 'camisa', 'L', 'Celeste', 4, 4, 0, 0, 0, 0, 12.00, 60.00, 'disponible'),
('5003', 'Camisa Moderna Blanca', 'camisa', 'M', 'Blanco', 4, 4, 0, 0, 0, 0, 12.00, 60.00, 'disponible'),
('5004', 'Camisa Elegante Blanca', 'camisa', 'S', 'Blanco', 4, 4, 0, 0, 0, 0, 12.00, 60.00, 'disponible'),
('5005', 'Camisa Premium Celeste', 'camisa', 'XL', 'Celeste', 4, 4, 0, 0, 0, 0, 15.00, 70.00, 'disponible')
ON CONFLICT (codigo) DO NOTHING;

-- 5 Zapatos (códigos 6001-6005)
INSERT INTO articulos (codigo, nombre, tipo, talla, color, cantidad, cantidad_disponible, cantidad_alquilada, cantidad_mantenimiento, cantidad_vendida, cantidad_perdida, precio_alquiler, precio_venta, estado) VALUES
('6001', 'Zapato Vestir Negro', 'zapato', '42', 'Negro', 3, 3, 0, 0, 0, 0, 15.00, 120.00, 'disponible'),
('6002', 'Zapato Clásico Marrón', 'zapato', '43', 'Marrón', 3, 3, 0, 0, 0, 0, 15.00, 120.00, 'disponible'),
('6003', 'Zapato Moderno Negro', 'zapato', '42', 'Negro', 3, 3, 0, 0, 0, 0, 15.00, 120.00, 'disponible'),
('6004', 'Zapato Elegante Negro', 'zapato', '41', 'Negro', 3, 3, 0, 0, 0, 0, 15.00, 120.00, 'disponible'),
('6005', 'Zapato Premium Marrón', 'zapato', '44', 'Marrón', 3, 3, 0, 0, 0, 0, 18.00, 140.00, 'disponible')
ON CONFLICT (codigo) DO NOTHING;

-- PASO 3: CREAR TRAJES COMPLETOS
-- Traje 1: Negro Ejecutivo (Talla M)
INSERT INTO trajes (nombre, descripcion) VALUES
('Traje Ejecutivo Negro M', 'Conjunto completo negro talla M para eventos formales y negocios')
ON CONFLICT DO NOTHING;

INSERT INTO traje_articulos (traje_id, articulo_id)
SELECT 
    (SELECT id FROM trajes WHERE nombre = 'Traje Ejecutivo Negro M' LIMIT 1),
    id
FROM articulos
WHERE codigo IN ('1001', '2001', '3001', '4001', '5001', '6001')
ON CONFLICT DO NOTHING;

-- Traje 2: Azul Marino Clásico (Talla L)
INSERT INTO trajes (nombre, descripcion) VALUES
('Traje Clásico Azul L', 'Conjunto azul marino talla L estilo tradicional elegante')
ON CONFLICT DO NOTHING;

INSERT INTO traje_articulos (traje_id, articulo_id)
SELECT 
    (SELECT id FROM trajes WHERE nombre = 'Traje Clásico Azul L' LIMIT 1),
    id
FROM articulos
WHERE codigo IN ('1002', '2002', '3002', '4002', '5002', '6002')
ON CONFLICT DO NOTHING;

-- Traje 3: Gris Moderno (Talla M)
INSERT INTO trajes (nombre, descripcion) VALUES
('Traje Moderno Gris M', 'Conjunto gris talla M diseño contemporáneo')
ON CONFLICT DO NOTHING;

INSERT INTO traje_articulos (traje_id, articulo_id)
SELECT 
    (SELECT id FROM trajes WHERE nombre = 'Traje Moderno Gris M' LIMIT 1),
    id
FROM articulos
WHERE codigo IN ('1003', '2003', '3003', '4003', '5003', '6003')
ON CONFLICT DO NOTHING;

-- Traje 4: Negro Elegante (Talla S)
INSERT INTO trajes (nombre, descripcion) VALUES
('Traje Elegante Negro S', 'Conjunto negro talla S para ocasiones especiales')
ON CONFLICT DO NOTHING;

INSERT INTO traje_articulos (traje_id, articulo_id)
SELECT 
    (SELECT id FROM trajes WHERE nombre = 'Traje Elegante Negro S' LIMIT 1),
    id
FROM articulos
WHERE codigo IN ('1004', '2004', '3004', '4004', '5004', '6004')
ON CONFLICT DO NOTHING;

-- Traje 5: Azul Premium (Talla XL)
INSERT INTO trajes (nombre, descripcion) VALUES
('Traje Premium Azul XL', 'Conjunto azul premium talla XL de alta calidad')
ON CONFLICT DO NOTHING;

INSERT INTO traje_articulos (traje_id, articulo_id)
SELECT 
    (SELECT id FROM trajes WHERE nombre = 'Traje Premium Azul XL' LIMIT 1),
    id
FROM articulos
WHERE codigo IN ('1005', '2005', '3005', '4005', '5005', '6005')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- RESUMEN DE DATOS CREADOS
-- ============================================================================
-- ✅ 9 Clientes con DNI repetido (11111111 hasta 99999999)
-- ✅ 30 Artículos en total:
--    - 5 Sacos (códigos 1001-1005)
--    - 5 Chalecos (códigos 2001-2005)
--    - 5 Corbatas (códigos 3001-3005)
--    - 5 Pantalones (códigos 4001-4005)
--    - 5 Camisas (códigos 5001-5005)
--    - 5 Zapatos (códigos 6001-6005)
-- ✅ 5 Trajes completos combinando todos los artículos:
--    - Traje Ejecutivo Negro M
--    - Traje Clásico Azul L
--    - Traje Moderno Gris M
--    - Traje Elegante Negro S
--    - Traje Premium Azul XL
-- ============================================================================

-- Verificar datos insertados
SELECT 'Clientes creados:' as info, COUNT(*) as total FROM clientes WHERE dni LIKE '%1111%' OR dni LIKE '%2222%' OR dni LIKE '%3333%' OR dni LIKE '%4444%' OR dni LIKE '%5555%' OR dni LIKE '%6666%' OR dni LIKE '%7777%' OR dni LIKE '%8888%' OR dni LIKE '%9999%'
UNION ALL
SELECT 'Artículos creados:', COUNT(*) FROM articulos WHERE codigo ~ '^[1-6]00[1-5]$'
UNION ALL
SELECT 'Trajes creados:', COUNT(*) FROM trajes WHERE nombre LIKE '%Traje%M%' OR nombre LIKE '%Traje%L%' OR nombre LIKE '%Traje%S%' OR nombre LIKE '%Traje%XL%';
