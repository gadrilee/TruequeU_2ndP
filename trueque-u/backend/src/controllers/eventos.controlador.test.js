jest.mock("../database/sequelize", () => ({
  models: {
    eventos: { create: jest.fn(), findAll: jest.fn() },
  },
}));

const { models } = require("../database/sequelize");
const { postEvento, getAnalitica } = require("./eventos.controlador");

function crearRespuesta() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe("Eventos y analitica", () => {
  beforeEach(() => {
    models.eventos.create.mockReset();
    models.eventos.findAll.mockReset();
  });

  test("guarda el evento con sus props", async () => {
    models.eventos.create.mockResolvedValue({});
    const res = crearRespuesta();
    const props = { id_publicacion: 5, categoria: "libros" };

    await postEvento({ body: { evento: "oferta_iniciada", props } }, res);

    expect(models.eventos.create).toHaveBeenCalledWith({
      evento: "oferta_iniciada",
      props,
    });
    expect(res.status).toHaveBeenCalledWith(201);
  });

  test("un evento vacio da error 400 y no guarda", async () => {
    const res = crearRespuesta();

    await postEvento({ body: { evento: "  ", props: {} } }, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(models.eventos.create).not.toHaveBeenCalled();
  });

  test("rechaza props con datos personales y no guarda", async () => {
    for (const clave of ["correo", "nombre", "telefono", "id_usuario", "email"]) {
      const res = crearRespuesta();

      await postEvento({ body: { evento: "oferta_enviada", props: { [clave]: "x" } } }, res);

      expect(res.status).toHaveBeenCalledWith(400);
    }
    expect(models.eventos.create).not.toHaveBeenCalled();
  });

  test("sin evento da error 400", async () => {
    const res = crearRespuesta();

    await postEvento({ body: {} }, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });

  test("la analitica devuelve cuantas veces ocurrio cada evento", async () => {
    models.eventos.findAll.mockResolvedValue([
      { evento: "oferta_iniciada", total: "3" },
      { evento: "oferta_enviada", total: "1" },
    ]);
    const res = crearRespuesta();

    await getAnalitica({}, res);

    expect(res.json).toHaveBeenCalledWith([
      { evento: "oferta_iniciada", total: 3 },
      { evento: "oferta_enviada", total: 1 },
    ]);
  });
});

describe("Eventos: casos limite", () => {
  let consolaError;

  beforeEach(() => {
    models.eventos.create.mockReset();
    models.eventos.findAll.mockReset();
    consolaError = jest.spyOn(console, "error").mockImplementation(() => {});
  });

  afterEach(() => {
    consolaError.mockRestore();
  });

  test("un evento sin props se guarda", async () => {
    models.eventos.create.mockResolvedValue({});
    const res = crearRespuesta();

    await postEvento({ body: { evento: "app_abierta" } }, res);

    expect(res.status).toHaveBeenCalledWith(201);
  });

  test("props que no son un objeto se aceptan", async () => {
    models.eventos.create.mockResolvedValue({});
    const res = crearRespuesta();

    await postEvento({ body: { evento: "app_abierta", props: "texto" } }, res);

    expect(res.status).toHaveBeenCalledWith(201);
  });

  test("guardar con un fallo responde 500", async () => {
    models.eventos.create.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await postEvento({ body: { evento: "app_abierta" } }, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });

  test("la analitica con un fallo responde 500", async () => {
    models.eventos.findAll.mockRejectedValue(new Error("caida"));
    const res = crearRespuesta();

    await getAnalitica({}, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});
