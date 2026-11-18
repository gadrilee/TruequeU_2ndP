const fs = require("fs");
const os = require("os");
const path = require("path");

jest.mock("cloudinary", () => ({
  v2: {
    config: jest.fn(),
    uploader: { upload: jest.fn(), destroy: jest.fn() },
  },
}));

const cloudinary = require("cloudinary").v2;
const { guardarImagen, borrarImagen } = require("./imagenes");

const png =
  "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

function enBase64(bytes) {
  return Buffer.from(bytes).toString("base64");
}

const jpg = enBase64([0xff, 0xd8, 0xff, 0xe0, 0x00]);

const ENV_ORIGINAL = process.env;

beforeEach(() => {
  jest.clearAllMocks();
  process.env = { ...ENV_ORIGINAL };
  delete process.env.CLOUDINARY_CLOUD_NAME;
  delete process.env.CLOUDINARY_API_KEY;
  delete process.env.CLOUDINARY_API_SECRET;
});

afterAll(() => {
  process.env = ENV_ORIGINAL;
});

describe("Guardar una foto en el disco", () => {
  const carpeta = fs.mkdtempSync(path.join(os.tmpdir(), "trueque-fotos-"));

  beforeEach(() => {
    process.env.IMAGENES_CARPETA = carpeta;
    process.env.PUERTO = "3000";
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

  test("una foto jpg se guarda con extension jpg", async () => {
    const guardada = await guardarImagen(`data:image/jpeg;base64,${jpg}`);

    expect(guardada.url).toMatch(/\.jpg$/);
  });

  test("sin PUERTO el enlace usa el puerto 3000", async () => {
    delete process.env.PUERTO;

    const guardada = await guardarImagen(png);

    expect(guardada.url).toMatch(/^http:\/\/localhost:3000\/uploads\//);
  });

  test("un archivo que no es jpg ni png se rechaza", async () => {
    const resultado = await guardarImagen("data:image/png;base64,aG9sYQ==");
    expect(resultado.error).toBe("La foto tiene que ser jpg o png");
  });

  test("una foto vacia se rechaza", async () => {
    const resultado = await guardarImagen("");
    expect(resultado.error).toBe("La foto tiene que ser jpg o png");
  });

  test("una foto de mas de 2 MB se rechaza", async () => {
    const grande = enBase64(Buffer.alloc(2 * 1024 * 1024 + 1, 1));

    const resultado = await guardarImagen(grande);

    expect(resultado.error).toBe("La foto puede pesar hasta 2 MB");
  });

  test("una cabecera png incompleta se rechaza", async () => {
    expect((await guardarImagen(enBase64([0x89, 0x00, 0x4e, 0x47]))).error).toBeDefined();
    expect((await guardarImagen(enBase64([0x89, 0x50, 0x00, 0x47]))).error).toBeDefined();
    expect((await guardarImagen(enBase64([0x89, 0x50, 0x4e, 0x00]))).error).toBeDefined();
  });

  test("una cabecera jpg incompleta se rechaza", async () => {
    expect((await guardarImagen(enBase64([0xff, 0x00, 0xff]))).error).toBeDefined();
    expect((await guardarImagen(enBase64([0xff, 0xd8, 0x00]))).error).toBeDefined();
  });

  test("borrar sin enlace no hace nada", async () => {
    await expect(borrarImagen(undefined)).resolves.toBeUndefined();
  });

  test("borrar un archivo que no existe no falla", async () => {
    await expect(borrarImagen("http://localhost:3000/uploads/no-existe.png?v=1")).resolves.toBeUndefined();
  });

  test("borrar un nombre con caracteres raros se ignora", async () => {
    const archivo = path.join(carpeta, "a b.png");
    fs.writeFileSync(archivo, "x");

    await borrarImagen("http://localhost:3000/uploads/a b.png");

    expect(fs.existsSync(archivo)).toBe(true);
  });

  test("sin IMAGENES_CARPETA usa la carpeta uploads por defecto", async () => {
    delete process.env.IMAGENES_CARPETA;

    await expect(borrarImagen("http://localhost:3000/uploads/no-existe-nunca.png")).resolves.toBeUndefined();
  });

  test("un enlace que no es de Cloudinary ni local no se borra", async () => {
    await borrarImagen("http://otro.com/foto.png");

    expect(cloudinary.uploader.destroy).not.toHaveBeenCalled();
  });

  test("un enlace de Cloudinary sin claves de nube no se borra", async () => {
    await borrarImagen("https://res.cloudinary.com/demo/image/upload/v1/trueque_u/abc123.png");

    expect(cloudinary.uploader.destroy).not.toHaveBeenCalled();
  });
});

describe("Guardar una foto en la nube", () => {
  function activarNube() {
    process.env.CLOUDINARY_CLOUD_NAME = "nube";
    process.env.CLOUDINARY_API_KEY = "clave";
    process.env.CLOUDINARY_API_SECRET = "secreto";
  }

  test("con claves incompletas se guarda en el disco", async () => {
    const carpeta = fs.mkdtempSync(path.join(os.tmpdir(), "trueque-nube-"));
    process.env.IMAGENES_CARPETA = carpeta;
    process.env.CLOUDINARY_CLOUD_NAME = "nube";
    process.env.CLOUDINARY_API_KEY = "clave";

    const guardada = await guardarImagen(png);

    expect(guardada.url).toContain("/uploads/");
    expect(cloudinary.uploader.upload).not.toHaveBeenCalled();
    fs.rmSync(carpeta, { recursive: true, force: true });
  });

  test("con solo el nombre de la nube se guarda en el disco", async () => {
    const carpeta = fs.mkdtempSync(path.join(os.tmpdir(), "trueque-nube-"));
    process.env.IMAGENES_CARPETA = carpeta;
    process.env.CLOUDINARY_CLOUD_NAME = "nube";

    await guardarImagen(png);

    expect(cloudinary.uploader.upload).not.toHaveBeenCalled();
    fs.rmSync(carpeta, { recursive: true, force: true });
  });

  test("una foto png se sube a Cloudinary", async () => {
    activarNube();
    cloudinary.uploader.upload.mockResolvedValue({ secure_url: "https://nube/png.png" });

    const guardada = await guardarImagen(png);

    expect(guardada).toEqual({ url: "https://nube/png.png" });
    expect(cloudinary.config).toHaveBeenCalledWith({
      cloud_name: "nube",
      api_key: "clave",
      api_secret: "secreto",
    });
    const [datos, opciones] = cloudinary.uploader.upload.mock.calls[0];
    expect(datos).toMatch(/^data:image\/png;base64,/);
    expect(opciones).toEqual(expect.objectContaining({ folder: "trueque_u", resource_type: "image" }));
  });

  test("una foto jpg se sube como jpeg", async () => {
    activarNube();
    cloudinary.uploader.upload.mockResolvedValue({ secure_url: "https://nube/jpg.jpg" });

    await guardarImagen(jpg);

    expect(cloudinary.uploader.upload.mock.calls[0][0]).toMatch(/^data:image\/jpeg;base64,/);
  });

  test("borrar un enlace de Cloudinary destruye la imagen", async () => {
    activarNube();
    cloudinary.uploader.destroy.mockResolvedValue({});

    await borrarImagen("https://res.cloudinary.com/demo/image/upload/v1/trueque_u/abc123.png");

    expect(cloudinary.config).toHaveBeenCalled();
    expect(cloudinary.uploader.destroy).toHaveBeenCalledWith("trueque_u/abc123");
  });
});
