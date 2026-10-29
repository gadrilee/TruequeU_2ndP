const { Router } = require("express");
const {
  postOferta,
  getOfertasRecibidas,
  getOfertasEnviadas,
  putOfertaAceptada,
  putOfertaRechazada,
  putOfertaCancelada,
} = require("../controllers/ofertas.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.get("/recibidas", exigirSesion, getOfertasRecibidas);
rutas.get("/enviadas", exigirSesion, getOfertasEnviadas);
rutas.post("/", exigirSesion, postOferta);
rutas.put("/:id/aceptada", exigirSesion, putOfertaAceptada);
rutas.put("/:id/rechazada", exigirSesion, putOfertaRechazada);
rutas.put("/:id/cancelada", exigirSesion, putOfertaCancelada);

module.exports = rutas;
