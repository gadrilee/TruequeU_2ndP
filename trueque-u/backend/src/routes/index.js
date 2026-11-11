const { Router } = require('express');
const usuariosRutas = require('./usuarios.rutas');
const sesionesRutas = require('./sesiones.rutas');
const recuperacionesRutas = require('./recuperaciones.rutas');
const publicacionesRutas = require('./publicaciones.rutas');
const reservasRutas = require('./reservas.rutas');
const intercambiosRutas = require('./intercambios.rutas');
const historialRutas = require('./historial.rutas');
const ofertasRutas = require('./ofertas.rutas');
const propuestasEntregaRutas = require('./propuestasEntrega.rutas');
const eventosRutas = require('./eventos.rutas');

const rutas = Router();

rutas.use('/usuarios', usuariosRutas);
rutas.use('/sesiones', sesionesRutas);
rutas.use('/recuperaciones', recuperacionesRutas);
rutas.use('/publicaciones', intercambiosRutas); // va primero: GET /intercambiadas no debe caer en GET /:id
rutas.use('/publicaciones', publicacionesRutas);
rutas.use('/publicaciones', reservasRutas); // reservar y descartar reserva (mismas URLs de siempre)
rutas.use('/historial', historialRutas);
rutas.use('/ofertas', ofertasRutas);
rutas.use('/propuestas-entrega', propuestasEntregaRutas);
rutas.use('/', eventosRutas);

module.exports = rutas;
