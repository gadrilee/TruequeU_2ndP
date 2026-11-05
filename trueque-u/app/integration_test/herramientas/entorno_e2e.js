const http = require("http");
const path = require("path");
const { execFile } = require("child_process");
const fs = require("fs");

process.chdir(__dirname);
process.env.PUERTO = "3000";
process.env.BD_HOST = "localhost";
process.env.BD_PUERTO = "5433";
process.env.BD_NOMBRE = "trueque_u";
process.env.BD_USUARIO = "postgres";
process.env.BD_CONTRASENA = "postgres";
delete process.env.BD_URL;

require(path.join(__dirname, "../../../backend/src/servidor.js"));

const migracion =
  fs.readFileSync(
    path.join(__dirname, "../../../base_de_datos/migracion_contraofertas.sql"),
    "utf8"
  ) +
  fs.readFileSync(
    path.join(__dirname, "../../../base_de_datos/migracion_intercambio_acordado.sql"),
    "utf8"
  );

const datos = fs.readFileSync(
  path.join(__dirname, "../../../base_de_datos/datos.sql"),
  "utf8"
);

function reiniciarBase(alTerminar) {
  const sql =
    "TRUNCATE usuarios, sesiones, publicaciones, historial, ofertas RESTART IDENTITY CASCADE;\n" +
    migracion +
    "\n" +
    datos;
  const proceso = execFile(
    "docker",
    ["exec", "-i", "trueque_u_bd", "psql", "-U", "postgres", "-d", "trueque_u", "-v", "ON_ERROR_STOP=1"],
    (error, salida, errores) => alTerminar(error, errores)
  );
  proceso.stdin.end(sql);
}

http
  .createServer((peticion, respuesta) => {
    respuesta.setHeader("Access-Control-Allow-Origin", "*");
    respuesta.setHeader("Access-Control-Allow-Headers", "*");
    respuesta.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
    if (peticion.method === "OPTIONS") {
      respuesta.writeHead(204);
      respuesta.end();
      return;
    }
    reiniciarBase((error, errores) => {
      if (error) {
        console.error("No se pudo reiniciar la base:", errores);
        respuesta.writeHead(500);
        respuesta.end("error");
        return;
      }
      respuesta.writeHead(200);
      respuesta.end("listo");
    });
  })
  .listen(3100, () => {
    console.log("Reinicio de la base escuchando en http://localhost:3100");
  });
