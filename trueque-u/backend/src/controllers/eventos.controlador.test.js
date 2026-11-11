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
