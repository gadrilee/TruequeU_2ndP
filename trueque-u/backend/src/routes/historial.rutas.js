const { Router } = require("express");
const { getHistorial } = require("../controllers/historial.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

// Historial de la persona con sesión: qué ocurrió con sus intercambios.
// Opcional: ?tipo=reservas o ?tipo=completados
rutas.get("/", exigirSesion, getHistorial);

module.exports = rutas;
