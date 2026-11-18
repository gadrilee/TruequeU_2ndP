jest.mock("./routes", () => {
  const { Router } = require("express");
  const rutas = Router();
  rutas.get("/prueba", (req, res) => res.json({ ok: true }));
  rutas.post("/eco", (req, res) => res.json(req.body));
  rutas.get("/fallo", () => {
    throw new Error("fallo inesperado");
  });
  return rutas;
});

const aplicacion = require("./aplicacion");

let servidor;
let base;
let consola;

beforeAll(async () => {
  await new Promise((resolver) => {
    servidor = aplicacion.listen(0, resolver);
  });
  base = `http://127.0.0.1:${servidor.address().port}`;
});

afterAll(async () => {
  await new Promise((resolver) => servidor.close(resolver));
});

beforeEach(() => {
  consola = jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consola.mockRestore();
});

describe("Aplicacion", () => {
  test("las rutas cuelgan de /api y permiten CORS", async () => {
    const respuesta = await fetch(`${base}/api/prueba`);

    expect(respuesta.status).toBe(200);
    expect(respuesta.headers.get("access-control-allow-origin")).toBe("*");
    expect(await respuesta.json()).toEqual({ ok: true });
  });

  test("lee el cuerpo JSON", async () => {
    const respuesta = await fetch(`${base}/api/eco`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ dato: 1 }),
    });

    expect(await respuesta.json()).toEqual({ dato: 1 });
  });

  test("una ruta que no existe responde 404", async () => {
    const respuesta = await fetch(`${base}/api/nada`);

    expect(respuesta.status).toBe(404);
    expect(await respuesta.json()).toEqual({ error: "Ruta no encontrada" });
  });

  test("una foto que no existe en /uploads responde 404", async () => {
    const respuesta = await fetch(`${base}/uploads/no-existe.png`);

    expect(respuesta.status).toBe(404);
  });

  test("un JSON mal formado responde 400", async () => {
    const respuesta = await fetch(`${base}/api/eco`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "{malo",
    });

    expect(respuesta.status).toBe(400);
    expect(await respuesta.json()).toEqual({ error: "Solicitud no válida" });
  });

  test("un error inesperado responde 500", async () => {
    const respuesta = await fetch(`${base}/api/fallo`);

    expect(respuesta.status).toBe(500);
    expect(await respuesta.json()).toEqual({ error: "Error interno del servidor" });
  });
});
