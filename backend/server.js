const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Rutas
const clientesRoutes = require('./routes/clientes');
const alquileresRoutes = require('./routes/alquileres');
const ventasRoutes = require('./routes/ventas');
const inventarioRoutes = require('./routes/inventario');
const reportesRoutes = require('./routes/reportes');
const configuracionRoutes = require('./routes/configuracion');

app.use('/api/clientes', clientesRoutes);
app.use('/api/alquileres', alquileresRoutes);
app.use('/api/ventas', ventasRoutes);
app.use('/api/inventario', inventarioRoutes);
app.use('/api/reportes', reportesRoutes);
app.use('/api/configuracion', configuracionRoutes);

// Ruta de prueba
app.get('/', (req, res) => {
  res.json({ message: 'API de Penguin Ternos funcionando correctamente' });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
