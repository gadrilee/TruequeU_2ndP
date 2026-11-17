const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const MAXIMO = 2 * 1024 * 1024;

function carpeta() {
  return process.env.IMAGENES_CARPETA || path.join(__dirname, "../../uploads");
}

function usarNube() {
  return Boolean(
    process.env.CLOUDINARY_CLOUD_NAME &&
      process.env.CLOUDINARY_API_KEY &&
      process.env.CLOUDINARY_API_SECRET,
  );
}

function leerImagen(texto) {
  const limpio = String(texto)
    .replace(/^data:image\/(png|jpeg|jpg);base64,/i, "")
    .replace(/\s/g, "");
  const buffer = Buffer.from(limpio, "base64");
  if (buffer.length === 0) {
    return { error: "La foto tiene que ser jpg o png" };
  }
  if (buffer.length > MAXIMO) {
    return { error: "La foto puede pesar hasta 2 MB" };
  }
  const esPng = buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47;
  const esJpg = buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  if (!esPng && !esJpg) {
    return { error: "La foto tiene que ser jpg o png" };
  }
  return { buffer, extension: esPng ? "png" : "jpg" };
}

function guardarLocal(leida) {
  const destino = carpeta();
  fs.mkdirSync(destino, { recursive: true });
  const nombre = `${crypto.randomBytes(16).toString("hex")}.${leida.extension}`;
  fs.writeFileSync(path.join(destino, nombre), leida.buffer);
  const puerto = process.env.PUERTO || 3000;
  return { url: `http://localhost:${puerto}/uploads/${nombre}` };
}

async function subirNube(leida) {
  const cloudinary = require("cloudinary").v2;
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  const id = crypto.randomBytes(16).toString("hex");
  const tipo = leida.extension === "png" ? "png" : "jpeg";
  const subida = await cloudinary.uploader.upload(
    `data:image/${tipo};base64,${leida.buffer.toString("base64")}`,
    { folder: "trueque_u", public_id: id, resource_type: "image" },
  );
  return { url: subida.secure_url };
}

async function guardarImagen(texto) {
  const leida = leerImagen(texto);
  if (leida.error) return leida;
  if (usarNube()) return subirNube(leida);
  return guardarLocal(leida);
}

async function borrarImagen(url) {
  if (!url) return;
  if (url.includes("/uploads/")) {
    const nombre = path.basename(url.split("?")[0]);
    if (!/^[\w.-]+$/.test(nombre)) return;
    const archivo = path.join(carpeta(), nombre);
    if (fs.existsSync(archivo)) fs.unlinkSync(archivo);
    return;
  }
  const id = url.match(/\/trueque_u\/([^./]+)/);
  if (!id || !usarNube()) return;
  const cloudinary = require("cloudinary").v2;
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  await cloudinary.uploader.destroy(`trueque_u/${id[1]}`);
}

module.exports = { guardarImagen, borrarImagen };
