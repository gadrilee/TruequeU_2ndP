const fs = require("fs");
const os = require("os");
const path = require("path");

const { guardarImagen, borrarImagen } = require("./imagenes");

const png =
  "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

describe("Guardar una foto en el disco", () => {
  const carpeta = fs.mkdtempSync(path.join(os.tmpdir(), "trueque-fotos-"));

  beforeEach(() => {
    process.env.IMAGENES_CARPETA = carpeta;
    process.env.PUERTO = "3000";
    delete process.env.CLOUDINARY_CLOUD_NAME;
    delete process.env.CLOUDINARY_API_KEY;
    delete process.env.CLOUDINARY_API_SECRET;
  });

  afterAll(() => {
    fs.rmSync(carpeta, { recursive: true, force: true });
  });

  test("sin claves de nube guarda un enlace local y al borrar desaparece el archivo", async () => {
    const guardada = await guardarImagen(png);

    expect(guardada.url).toMatch(/^http:\/\/localhost:3000\/uploads\/[a-f0-9]+\.png$/);
    const nombre = path.basename(guardada.url);
    expect(fs.existsSync(path.join(carpeta, nombre))).toBe(true);

    await borrarImagen(guardada.url);
    expect(fs.existsSync(path.join(carpeta, nombre))).toBe(false);
  });

  test("un archivo que no es jpg ni png se rechaza", async () => {
    const resultado = await guardarImagen("data:image/png;base64,aG9sYQ==");
    expect(resultado.error).toBe("La foto tiene que ser jpg o png");
  });
});
