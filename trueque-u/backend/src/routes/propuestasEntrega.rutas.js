const { Router } = require("express");
const {
  getPropuestasEntrega,
  postPropuestaEntrega,
  postContrapropuestaEntrega,
  putPropuestaEntregaAceptada,
} = require("../controllers/propuestasEntrega.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.get("/", exigirSesion, getPropuestasEntrega);
rutas.post("/", exigirSesion, postPropuestaEntrega);
rutas.post("/:id/contrapropuesta", exigirSesion, postContrapropuestaEntrega);
rutas.put("/:id/aceptada", exigirSesion, putPropuestaEntregaAceptada);

module.exports = rutas;
