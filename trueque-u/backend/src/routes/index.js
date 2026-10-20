const { Router } = require('express');
const usuariosRutas = require('./usuarios.rutas');
const sesionesRutas = require('./sesiones.rutas');
const recuperacionesRutas = require('./recuperaciones.rutas');
const publicacionesRutas = require('./publicaciones.rutas');
const reservasRutas = require('./reservas.rutas');
const intercambiosRutas = require('./intercambios.rutas');
const historialRutas = require('./historial.rutas');

const rutas = Router();

rutas.use('/usuarios', usuariosRutas);
rutas.use('/sesiones', sesionesRutas);
rutas.use('/recuperaciones', recuperacionesRutas);
rutas.use('/publicaciones', intercambiosRutas); // va primero: GET /intercambiadas no debe caer en GET /:id
rutas.use('/publicaciones', publicacionesRutas);
rutas.use('/publicaciones', reservasRutas); // reservar y descartar reserva (mismas URLs de siempre)
rutas.use('/historial', historialRutas);

module.exports = rutas;
