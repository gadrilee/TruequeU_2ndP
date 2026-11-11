const { Router } = require("express");
const { postEvento, getAnalitica } = require("../controllers/eventos.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.post("/eventos", exigirSesion, postEvento);
rutas.get("/analitica", exigirSesion, getAnalitica);

module.exports = rutas;
