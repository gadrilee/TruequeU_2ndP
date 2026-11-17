const path = require("path");
const express = require("express");
const cors = require("cors");
const rutas = require("./routes");
const {
  rutaNoEncontrada,
  manejarErrores,
} = require("./middleware/errores.middleware");

const aplicacion = express();

aplicacion.use(cors());
aplicacion.use(express.json({ limit: "4mb" }));
aplicacion.use("/uploads", express.static(path.join(__dirname, "../uploads")));

aplicacion.use("/api", rutas);

aplicacion.use(rutaNoEncontrada);
aplicacion.use(manejarErrores);

module.exports = aplicacion;
