const { rutaNoEncontrada, manejarErrores } = require("./errores.middleware");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe("Ruta no encontrada", () => {
  test("responde 404", () => {
    const res = crearRespuesta();

    rutaNoEncontrada({}, res);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({ error: "Ruta no encontrada" });
  });
});

describe("Manejar errores", () => {
  let consola;

  beforeEach(() => {
    consola = jest.spyOn(console, "error").mockImplementation(() => {});
  });

  afterEach(() => {
    consola.mockRestore();
  });

  test("un error del cliente responde con su estado sin mostrarlo en consola", () => {
    const res = crearRespuesta();

    manejarErrores({ status: 400 }, {}, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: "Solicitud no válida" });
    expect(consola).not.toHaveBeenCalled();
  });

  test("un error con estado 500 o mayor se muestra en consola", () => {
    const res = crearRespuesta();
    const error = { status: 503 };

    manejarErrores(error, {}, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(503);
    expect(res.json).toHaveBeenCalledWith({ error: "Error interno del servidor" });
    expect(consola).toHaveBeenCalledWith(error);
  });

  test("un error sin estado responde 500", () => {
    const res = crearRespuesta();

    manejarErrores(new Error("fallo"), {}, res, jest.fn());

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
