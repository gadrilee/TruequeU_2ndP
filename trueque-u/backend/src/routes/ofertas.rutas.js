const { Router } = require("express");
const {
  postOferta,
  getOfertasRecibidas,
  getOfertasEnviadas,
  putOfertaAceptada,
  putOfertaRechazada,
  putOfertaCancelada,
  putOfertaEntrega,
  putOfertaAnulada,
  postContraoferta,
  getHistorialOferta,
} = require("../controllers/ofertas.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.get("/recibidas", exigirSesion, getOfertasRecibidas);
rutas.get("/enviadas", exigirSesion, getOfertasEnviadas);
rutas.post("/", exigirSesion, postOferta);
rutas.post("/:id/contraoferta", exigirSesion, postContraoferta);
rutas.get("/:id/historial", exigirSesion, getHistorialOferta);
rutas.put("/:id/aceptada", exigirSesion, putOfertaAceptada);
rutas.put("/:id/rechazada", exigirSesion, putOfertaRechazada);
rutas.put("/:id/cancelada", exigirSesion, putOfertaCancelada);
rutas.put("/:id/entrega", exigirSesion, putOfertaEntrega);
rutas.put("/:id/anulada", exigirSesion, putOfertaAnulada);

module.exports = rutas;
