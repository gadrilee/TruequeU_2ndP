const { Router } = require("express");
const {
  getNotificaciones,
  putNotificacionLeida,
} = require("../controllers/notificaciones.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.get("/", exigirSesion, getNotificaciones);
rutas.put("/:id/leida", exigirSesion, putNotificacionLeida);

module.exports = rutas;
