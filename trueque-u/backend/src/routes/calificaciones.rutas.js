const { Router } = require("express");
const {
  getMiCalificacion,
  postCalificacion,
  getResumenCalificaciones,
} = require("../controllers/calificaciones.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.get("/", exigirSesion, getMiCalificacion);
rutas.post("/", exigirSesion, postCalificacion);
rutas.get("/resumen", exigirSesion, getResumenCalificaciones);

module.exports = rutas;
