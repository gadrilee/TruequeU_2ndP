const { Router } = require("express");
const {
  postUsuario,
  putContrasena,
} = require("../controllers/usuarios.controlador");
const { deleteCuenta } = require("../controllers/cuenta.controlador");
const { getMisDatos, deleteTelefono } = require("../controllers/misDatos.controlador");
const { exigirSesion } = require("../middleware/autenticacion.middleware");

const rutas = Router();

rutas.post("/", postUsuario); // pública: registro
rutas.put("/contrasena", exigirSesion, putContrasena); // privada: cambio de contraseña
rutas.get("/yo/datos", exigirSesion, getMisDatos);
rutas.delete("/yo", exigirSesion, deleteCuenta);
rutas.delete("/yo/telefono", exigirSesion, deleteTelefono);

module.exports = rutas;
