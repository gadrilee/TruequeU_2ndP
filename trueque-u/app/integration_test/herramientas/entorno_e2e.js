const http = require("http");
const path = require("path");
const fs = require("fs");

const raiz = path.join(__dirname, "../../..");
const { Pool } = require(path.join(raiz, "backend/node_modules/pg"));

const conexion = {
  host: process.env.BD_HOST || "localhost",
  port: Number(process.env.BD_PUERTO || 5433),
  database: process.env.BD_NOMBRE || "trueque_u",
  user: process.env.BD_USUARIO || "postgres",
  password: process.env.BD_CONTRASENA || "postgres",
};

process.chdir(__dirname);
process.env.PUERTO = "3000";
process.env.BD_HOST = conexion.host;
process.env.BD_PUERTO = String(conexion.port);
process.env.BD_NOMBRE = conexion.database;
process.env.BD_USUARIO = conexion.user;
process.env.BD_CONTRASENA = conexion.password;
delete process.env.BD_URL;

let ultimaClaveTemporal = "";
const escribirOriginal = console.log;
console.log = (...argumentos) => {
  const clave = /Tu nueva contraseña es: (\S+)/.exec(argumentos.join(" "));
  if (clave) ultimaClaveTemporal = clave[1];
  escribirOriginal(...argumentos);
};

require(path.join(raiz, "backend/src/servidor.js"));

const pool = new Pool(conexion);

const leerSql = (nombre) =>
  fs.readFileSync(path.join(raiz, "base_de_datos", nombre), "utf8");

const migracion = [
  "migracion_contraofertas.sql",
  "migracion_intercambio_acordado.sql",
  "migracion_propuestas_entrega.sql",
  "migracion_calificaciones.sql",
  "migracion_eventos.sql",
  "migracion_cuenta_eliminada.sql",
  "migracion_imagen.sql",
]
  .map(leerSql)
  .join("");

const datos = leerSql("datos.sql");

async function reiniciarBase() {
  const sql =
    "TRUNCATE usuarios, sesiones, publicaciones, historial, ofertas RESTART IDENTITY CASCADE;\n" +
    migracion +
    "\n" +
    datos;
  await pool.query(sql);
}

async function leerEventos() {
  const resultado = await pool.query(
    "SELECT COALESCE(json_agg(props), '[]') AS eventos FROM eventos"
  );
  return JSON.stringify(resultado.rows[0].eventos);
}

http
  .createServer((peticion, respuesta) => {
    respuesta.setHeader("Access-Control-Allow-Origin", "*");
    respuesta.setHeader("Access-Control-Allow-Headers", "*");
    respuesta.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    if (peticion.method === "OPTIONS") {
      respuesta.writeHead(204);
      respuesta.end();
      return;
    }
    if (peticion.method === "GET" && peticion.url === "/ultima-clave-temporal") {
      respuesta.writeHead(200, { "Content-Type": "text/plain" });
      respuesta.end(ultimaClaveTemporal);
      return;
    }
    if (peticion.method === "GET") {
      leerEventos().then(
        (eventos) => {
          respuesta.writeHead(200, { "Content-Type": "application/json" });
          respuesta.end(eventos);
        },
        (error) => {
          console.error("No se pudieron leer los eventos:", error.message);
          respuesta.writeHead(500, { "Content-Type": "application/json" });
          respuesta.end("error");
        }
      );
      return;
    }
    reiniciarBase().then(
      () => {
        respuesta.writeHead(200);
        respuesta.end("listo");
      },
      (error) => {
        console.error("No se pudo reiniciar la base:", error.message);
        respuesta.writeHead(500);
        respuesta.end("error");
      }
    );
  })
  .listen(3100, () => {
    console.log("Reinicio de la base escuchando en http://localhost:3100");
  });
