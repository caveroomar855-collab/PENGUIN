const request = require('supertest');
const express = require('express');
const bodyParser = require('body-parser');

// 1. DEFINICIÓN DEL MOCK (Antes de los imports)
const mockSupabase = {
  from: jest.fn(),
  rpc: jest.fn()
};

// 2. ACTIVAR EL MOCK
jest.mock('../config/database', () => mockSupabase);

// 3. IMPORTAR RUTAS (Después del mock)
const alquileresRouter = require('../routes/alquileres');

const app = express();
app.use(bodyParser.json());
app.use('/alquileres', alquileresRouter);

describe('Cálculo de Moras en Devoluciones', () => {
  
  // "Base de datos" temporal para nuestros tests
  let dbMockData = {};

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    dbMockData = {}; // Limpiamos los datos antes de cada test

    // --- MOCK INTELIGENTE DE SUPABASE ---
    // Configuramos 'from' una sola vez para que busque en dbMockData
    mockSupabase.from.mockImplementation((tableName) => {
      const dataToReturn = dbMockData[tableName]; // Busca los datos según la tabla que pida el código
      
      return {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        in: jest.fn().mockReturnThis(),
        order: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: dataToReturn, error: null }),
        // Agregamos update y insert por si acaso, devolviendo éxito
        update: jest.fn().mockReturnThis(),
        insert: jest.fn().mockReturnThis(),
      };
    });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  // Helper simplificado: Solo guarda datos en nuestro diccionario
  const mockDbResponse = (tableName, data) => {
    dbMockData[tableName] = data;
  };

  test('Debe calcular mora correctamente cuando hay retraso simple', async () => {
    const fechaFin = '2023-10-01T12:00:00Z';
    const diasRetraso = 5;
    const costoMoraDiaria = 10;
    
    // 1. Fijar fecha actual: 6 de Octubre (5 días después)
    jest.setSystemTime(new Date('2023-10-06T12:00:00Z'));

    // 2. Cargar datos en nuestro mock de Alquileres
    mockDbResponse('alquileres', {
      id: 1,
      fecha_fin: fechaFin,
      garantia: 100,
      estado: 'activo'
    });

    // 3. Cargar datos en nuestro mock de Configuración
    mockDbResponse('configuracion', {
      mora_diaria: costoMoraDiaria,
      dias_maximos_mora: 30
    });

    // 4. Mock del RPC (éxito)
    mockSupabase.rpc.mockResolvedValue({ data: { success: true }, error: null });
    
    // EJECUCIÓN
    const res = await request(app)
      .post('/alquileres/1/devolucion')
      .send({ articulos: [] });

    // VERIFICACIÓN
    expect(res.status).not.toBe(500);

    // Verificamos la llamada RPC
    expect(mockSupabase.rpc).toHaveBeenCalled();
    const rpcCallArgs = mockSupabase.rpc.mock.calls[0][1];
    
    console.log("Mora calculada:", rpcCallArgs.p_mora); // Debería imprimir 50

    expect(rpcCallArgs).toEqual(expect.objectContaining({
      p_alquiler: '1',
      p_mora: 50 
    }));
  });
});